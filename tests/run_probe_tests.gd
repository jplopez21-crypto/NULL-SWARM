extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	check(not ProjectSettings.get_setting("qa/android_runtime_probe", false), "distributed project disables emulator telemetry by default")
	game.save.path = "user://qa_probe_test.json"
	game.save.data = SaveStore.defaults()
	game.start_run()
	game.audio.shutdown()
	var before: Dictionary = game.save.data.duplicate(true)
	var position: Vector3 = game.player.position
	var probe: Node = load("res://systems/android_qa_probe.gd").new()
	probe.game = game
	game.add_child(probe)
	probe.set_process(false)
	probe.snapshot()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["state"] == "playing" and data["ranks"] == game.progress.ranks, "probe reports real game state")
	var settings_match: bool = true
	for key in game.save.data["settings"]:
		var expected: Variant = game.save.data["settings"][key]
		var actual: Variant = data["settings"].get(key)
		if expected is bool:
			settings_match = settings_match and actual is bool and actual == expected
		else:
			settings_match = settings_match and (actual is int or actual is float) and is_equal_approx(float(actual), float(expected))
	check(settings_match and data["buttons"].size() >= 2, "probe reports settings and actual touchable controls")
	check(before == game.save.data and game.player.position == position and game.player.health.current == 100 and game.combat.director.elapsed == 0, "snapshot cannot grant stats advance simulation or alter progression")
	game.change_setting("performance_stats", true)
	game._process(0)
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["performance_stats_visible"] and data["performance_stats_text"].contains("ENEMIES"), "read-only telemetry observes actual enabled HUD diagnostics")
	game.pause_run()
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["state"] == "paused", "probe observes normal pause transition")
	game.open_build()
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["build_text"].contains("DEPLOYMENT BUILD") and data["build_text"].contains("AMPLIFIED PULSE 0/3"), "probe reads visible build guide labels without inventing ranks")
	game.resume_run()
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["build_text"].is_empty(), "probe clears build text after resume")
	game.audio.shutdown()
	# Drain queued UI tweens and audio-thread releases before destroying the scene.
	await create_timer(0.20).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.05).timeout
	QAReport.write("res://builds/qa/probe-tests.json", {"checks": checks, "failures": failures})
	print("PROBE_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

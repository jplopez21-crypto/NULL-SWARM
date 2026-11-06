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
	check(data["attack_lanes"]["charge"]["triangles"] == 12 and data["attack_lanes"]["sentry"]["triangles"] == 7 and data["attack_lanes"]["charge"]["surfaces"] == 1 and data["attack_lanes"]["sentry"]["surfaces"] == 1, "probe reads actual pooled charge/sentry warning meshes without inventing a live attack")
	check(data["attack_lanes"]["charge"]["ground_mesh"] and data["attack_lanes"]["sentry"]["ground_mesh"] and data["attack_lanes"]["charge"]["length"] == 7 and data["attack_lanes"]["sentry"]["length"] == 7, "probe observes shared directional ground geometry with retained base length")
	check(data["operative_visuals"] == {"instances": 5.0, "surfaces": 6.0, "triangles": 296.0}, "probe reads actual operative geometry without replacing or posing it")
	check(data["destruction_feedback"] == {"fragments_live": 0.0, "fragment_triangles": 8.0, "kill_cue_last_dispatch_ms": -1.0, "kill_cue_pcm_bytes": 0.0, "kill_cue_pcm_sha256": ""}, "probe reports actual empty fragments and shut-down audio without inventing dispatch")
	game.combat.effects.destruction(Vector3.ZERO, Color.RED, false)
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["destruction_feedback"]["fragments_live"] == 4 and game.combat.effects.live.size() == 5, "probe counts actual pooled chips without spawning or advancing effects")
	check(data["touch_controls"] == {"joystick_id": -1.0, "stick": [0.0, 0.0], "dash_id": -1.0, "dash_enabled": true, "pause_id": -1.0, "pause_enabled": true}, "probe reads actual idle touch ownership without injecting input")
	check(data["memory_audio_plays"] == game.audio.memory_plays and game.audio.memory_plays == 0, "probe reads the actual audio counter without starting or granting anything")
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
	check(not data["touch_controls"]["pause_enabled"] and not data["touch_controls"]["dash_enabled"] and data["touch_controls"]["pause_id"] == -1 and data["touch_controls"]["joystick_id"] == -1, "probe observes actual cleared/disabled controls after pause without injecting reset")
	game.open_build()
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["build_text"].contains("DEPLOYMENT BUILD") and data["build_text"].contains("AMPLIFIED PULSE 0/3"), "probe reads visible build guide labels without inventing ranks")
	game.resume_run()
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["build_text"].is_empty(), "probe clears build text after resume")
	game.pause_run()
	game.ui.show_settings(game.save.data["settings"], func(): game.ui.show_pause(game.save.data["settings"]))
	game.open_performance_report()
	var report_save: Dictionary = game.save.data.duplicate(true)
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["performance_report_text"] == game.ui.visible_performance_report() and not data["performance_report_text"].is_empty(), "probe reads the actual report without inventing observations")
	check(data["edit_fields"].is_empty() and data["backup_code_length"] == 0 and game.save.data == report_save, "read-only performance text is never advertised as a backup input or progression grant")
	game.combat.damage_by_weapon = {"pulse": 8.0, "drone": 2.0}
	game.finish_run(false)
	game.open_run_analysis()
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["run_analysis_text"] == game.ui.visible_run_analysis() and data["run_analysis_text"].contains("DRONE SYSTEMS"), "probe observes actual post-run analysis labels")
	check(data["damage_by_weapon"] == game.combat.damage_by_weapon and data["combat_rng"] == str(game.combat.rng.state), "analysis telemetry is an exact read-only observation of damage and RNG")
	game.show_results()
	probe.snapshot()
	data = JSON.parse_string(FileAccess.get_file_as_string("user://qa-runtime.json"))
	check(data["run_analysis_text"].is_empty(), "probe clears retired analysis text after returning to results")
	check(data["results_title"] == "SIGNAL LOST", "probe observes the visible production result heading")
	game.audio.shutdown()
	# Drain queued UI tweens and audio-thread releases before destroying the scene.
	await create_timer(0.20).timeout
	game.queue_free()
	await process_frame
	await create_timer(0.05).timeout
	QAReport.write("res://builds/qa/probe-tests.json", {"checks": checks, "failures": failures})
	print("PROBE_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

extends SceneTree

var failures: Array[String] = []
var checks: int = 0
var layouts: Array[Dictionary] = []
var captures: bool = false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in range(5):
		await process_frame

func inspect(game: Node3D, stage: String, size: Vector2i) -> void:
	await settle()
	var bounds: Rect2 = game.ui.root.get_global_rect().grow(1.0)
	check(root.size == size, "%s %s: requested window size applied" % [size, stage])
	var buttons: int = 0
	for node in game.ui.root.find_children("*", "Button", true, false):
		if node.is_visible_in_tree():
			buttons += 1
			check(bounds.encloses(node.get_global_rect()), "%s %s: button outside viewport: %s" % [size, stage, node.text])
			check(node.size.y >= 55.0, "%s %s: undersized button" % [size, stage])
	if game.ui.screen != null:
		check(bounds.encloses(game.ui.screen.get_global_rect()), "%s %s: panel outside viewport" % [size, stage])
	layouts.append({"window": [size.x, size.y], "observed_window": [root.size.x, root.size.y], "canvas": [game.ui.root.size.x, game.ui.root.size.y], "scale_aspect": root.content_scale_aspect, "stage": stage, "visible_buttons": buttons})
	if captures:
		await create_timer(0.20).timeout
		await RenderingServer.frame_post_draw
		var path := "res://builds/qa/ui/%dx%d-%s.png" % [size.x, size.y, stage]
		root.get_texture().get_image().save_png(path)

func run() -> void:
	captures = "--capture-ui" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://builds/qa/ui")
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.save.path = "user://qa_ui_lifecycle.json"
	game.save.data = SaveStore.defaults()
	game.audio.shutdown()
	for size in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1280, 960), Vector2i(960, 600)]:
		root.size = size
		await settle()
		game.go_menu()
		await inspect(game, "menu", size)
		game.ui.show_settings(game.save.data["settings"], func(): game.go_menu())
		await inspect(game, "settings", size)
		game.start_run()
		game.set_physics_process(false)
		game.pickups.drop(Vector3(12, 0, -5), 100)
		game._process(0.3)
		check(game.ui.memory_visible and is_instance_valid(game.ui.memory_packet), "memory cue acquires packet after deployment")
		await inspect(game, "combat", size)
		game.combat.adaptation.pending = "insulators"
		game.combat.adaptation.starts_at = game.combat.adaptation.elapsed + 8.0
		game.ui.toast("SWARM ADAPTING // 8s WARNING", "AMBER CORES RESIST ARC 20% // OTHER WEAPONS WORK NORMALLY", GameUI.CYAN)
		game._process(0.0)
		await inspect(game, "adaptation", size)
		var press := InputEventScreenTouch.new()
		press.index = 2
		press.pressed = true
		press.position = Vector2(100, 400)
		game.input_router.handle(press, game.ui.root.size)
		var drag := InputEventScreenDrag.new()
		drag.index = 2
		drag.position = Vector2(160, 400)
		game.input_router.handle(drag, game.ui.root.size)
		game.input_router.dash_requested = true
		check(game.input_router.stick.length() > 0, "touch fixture moves before pause")
		game.pause_run()
		game._process(0.1)
		check(not game.ui.memory_visible and game.input_router.touch_id == -1 and not game.input_router.dash_requested, "pause hides memory and releases movement/dash")
		var clock: float = game.combat.director.elapsed
		game._physics_process(10.0)
		check(game.combat.director.elapsed == clock, "paused UI preserves simulation clock")
		await inspect(game, "pause", size)
		game.resume_run()
		game._process(0.3)
		check(game.ui.memory_visible and game.input_router.stick == Vector2.ZERO, "resume reacquires cue without stuck movement")
		game.progress.pending = 1
		game.show_upgrade()
		game._process(0.1)
		check(not game.ui.memory_visible, "upgrade selection hides memory cue")
		await inspect(game, "upgrades", size)
		game.select_upgrade(game.offered[0])
		game._process(0.3)
		check(game.state == game.State.PLAYING and game.ui.memory_visible, "legal upgrade returns to guidance")
		game.progress.level = 5
		game.progress.pending = 1
		game.show_upgrade()
		await inspect(game, "unstable_offer", size)
		var saved_offer: Array = game.offered.duplicate()
		var saved_rng: int = game.combat.rng.state
		game.show_corruption()
		await inspect(game, "corruption", size)
		check(game.corruption_panel, "optional corruption panel opens at level five")
		game.return_upgrades()
		check(game.offered == saved_offer and game.combat.rng.state == saved_rng, "declining corruption preserves upgrade cards")
		game.show_corruption()
		game.select_corruption("redline")
		game._process(0.3)
		check(game.state == game.State.PLAYING and game.player.health.maximum == 80 and game.ui.corruption_label.text.contains("1/3"), "accepted link updates gameplay and HUD")
		await inspect(game, "corrupted", size)
		game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
		game._process(0.1)
		check(game.state == game.State.PAUSED and not game.ui.memory_visible, "focus loss pauses and hides guidance")
		game.resume_run()
		game.start_run()
		await settle()
		game._process(0.3)
		check(not game.ui.memory_visible and not is_instance_valid(game.ui.memory_packet), "restart clears freed packet reference")
		game.finish_run(false)
		game._process(0.1)
		check(not game.ui.memory_visible, "results hide guidance")
		await inspect(game, "results", size)
		game.ui.show_lab(game.save.data, func(): game.go_menu())
		await inspect(game, "foundry", size)
	game.audio.shutdown()
	game.queue_free()
	await settle()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute("user://qa_ui_lifecycle.json" + suffix)
	QAReport.write("res://builds/qa/ui-report.json", {"checks": checks, "failures": failures, "layouts": layouts, "captured": captures, "limitations": ["Project KEEP scaling preserves a 1280x720 logical canvas and letterboxes differing window ratios; window sizes are verified separately.", "Desktop/software rendering; does not emulate Android cutouts, lifecycle process death, real multitouch latency or device performance."]})
	print("UI_RESULT checks=", checks, " layouts=", layouts.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

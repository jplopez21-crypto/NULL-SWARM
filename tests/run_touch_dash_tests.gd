extends SceneTree

var checks: int = 0
var failures: Array[String] = []
var signals_seen: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func touch(index: int, down: bool, at: Vector2, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.pressed = down
	event.position = root.get_screen_transform() * at
	event.canceled = canceled
	# Use the engine Input path, including real touch-to-mouse emulation.
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(index: int, at: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = root.get_screen_transform() * at
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func settle() -> void:
	for i in range(4):
		await process_frame

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.save.path = "user://qa_multitouch_dash.json"
	game.save.data = SaveStore.defaults()
	game.audio.shutdown()
	game.ui.dash.connect(func(): signals_seen += 1)
	check(Input.emulate_mouse_from_touch, "regression runs with actual default touch-to-mouse emulation enabled")
	for size in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(960, 600)]:
		root.size = size
		game.start_run()
		await settle()
		var point: Vector2 = game.ui.dash_button.get_global_rect().get_center()
		var origin := Vector2(120, game.ui.root.size.y - 120)
		var held := origin + Vector2(75, 0)
		var count: int = signals_seen
		touch(0, true, origin)
		drag(0, held)
		touch(1, true, point)
		check(game.input_router.dash_requested and signals_seen == count + 1, "second finger dashes immediately while joystick is held: %s" % size)
		check(game.input_router.touch_id == 0 and game.input_router.movement() == Vector2.RIGHT, "dash does not steal or cancel held movement: %s" % size)
		game._physics_process(0.01)
		check(game.player.dash_cooldown > 0 and is_equal_approx(game.player.position.x, 0.27), "moving touch request reaches real physics and dashes along stick: %s" % size)
		drag(1, point + Vector2(-300, -180))
		touch(1, false, point + Vector2(-300, -180))
		check(game.input_router.movement() == Vector2.RIGHT and game.ui.dash_button.touch_id == -1, "dash release outside button leaves joystick running: %s" % size)
		check(not game.input_router.dash_requested and signals_seen == count + 1, "native touch release cannot trigger emulated-mouse duplicate: %s" % size)
		touch(0, false, held)
		check(game.input_router.movement() == Vector2.ZERO, "joystick still releases normally after multitouch dash: %s" % size)

		# Reverse finger order and nonzero pointer IDs, with a third-finger tap.
		count = signals_seen
		touch(5, true, point)
		touch(9, true, origin)
		drag(9, held)
		touch(12, true, point)
		touch(12, false, point)
		check(game.input_router.dash_requested and game.input_router.touch_id == 9 and game.input_router.movement() == Vector2.RIGHT, "dash-first pointer order still permits movement: %s" % size)
		check(game.ui.dash_button.touch_id == 5 and signals_seen == count + 1, "third finger cannot steal dash ownership or retrigger it: %s" % size)
		game._physics_process(0.01)
		check(not game.input_router.dash_requested and signals_seen == count + 1, "cooldown consumes rejected press without queuing an extra dash: %s" % size)
		# Wait beyond cooldown with dash held: no automatic repeat on readiness.
		game.player.tick(3.1, Vector2.ZERO, false)
		game._physics_process(0.01)
		check(game.player.dash_cooldown == 0 and signals_seen == count + 1, "holding dash through cooldown never auto-repeats: %s" % size)
		touch(9, false, held)
		touch(5, false, point)
		check(not game.input_router.dash_requested and signals_seen == count + 1, "primary emulated-mouse release never adds a dash: %s" % size)

		count = signals_seen
		touch(2, true, origin)
		drag(2, held)
		touch(3, true, point)
		touch(2, false, held)
		check(game.input_router.dash_requested and game.input_router.movement() == Vector2.ZERO, "same-frame joystick release preserves independent dash request: %s" % size)
		game._physics_process(0.01)
		check(game.player.dash_cooldown > 0, "preserved release-race request is accepted by real physics: %s" % size)
		touch(3, false, point, true)
		check(game.ui.dash_button.touch_id == -1 and signals_seen == count + 1, "canceled owning touch clears hold without another activation: %s" % size)

		count = signals_seen
		touch(4, true, point + Vector2(-220, 0))
		drag(4, point)
		touch(4, false, point)
		check(signals_seen == count and not game.input_router.dash_requested, "dragging into dash from outside cannot activate it: %s" % size)
		touch(6, true, point, true)
		touch(6, false, point, true)
		check(signals_seen == count and game.ui.dash_button.touch_id == -1, "canceled new pointer is never interpreted as a dash: %s" % size)

		touch(7, true, point)
		game.pause_run()
		check(game.ui.dash_button.touch_id == -1 and not game.input_router.dash_requested, "pause clears independent touch ownership and pending dash: %s" % size)
		count = signals_seen
		touch(8, true, point)
		touch(8, false, point)
		check(signals_seen == count and not game.input_router.dash_requested, "paused HUD cannot accept or queue dash: %s" % size)
		game.resume_run()
		touch(7, false, point)
		check(signals_seen == count and not game.input_router.dash_requested, "resume ignores release of pre-pause finger: %s" % size)
		game.progress.pending = 1
		game.show_upgrade()
		touch(8, true, point)
		touch(8, false, point)
		check(signals_seen == count and not game.input_router.dash_requested, "upgrade screen cannot queue hidden dash: %s" % size)
		game.select_upgrade(game.offered[0])
		await settle()
		check(game.state == game.State.PLAYING and game.ui.dash_button.input_enabled, "real upgrade selection re-enables combat dash: %s" % size)

	# Desktop mouse, keyboard and controller retain their existing input paths.
	var point: Vector2 = game.ui.dash_button.get_global_rect().get_center()
	var count: int = signals_seen
	var mouse := InputEventMouseButton.new()
	mouse.position = root.get_screen_transform() * point
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	check(game.input_router.dash_requested and signals_seen == count + 1, "real mouse down still activates dash immediately")
	game.input_router.dash_requested = false
	mouse = mouse.duplicate()
	mouse.pressed = false
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	check(not game.input_router.dash_requested and signals_seen == count + 1, "real mouse release never double-activates dash")
	game.ui.dash_button.release_focus()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(game.input_router.dash_requested, "keyboard Space still requests dash")
	game.input_router.dash_requested = false
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_A
	joy.pressed = true
	Input.parse_input_event(joy)
	Input.flush_buffered_events()
	check(game.input_router.dash_requested, "controller A still requests dash")
	joy = joy.duplicate()
	joy.pressed = false
	Input.parse_input_event(joy)
	Input.flush_buffered_events()
	touch(10, true, point)
	game.ui.dash_button._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.ui.dash_button.touch_id == -1 and not game.input_router.dash_requested and game.state == game.State.PAUSED, "focus interruption clears dash and joystick state")
	touch(10, false, point)
	game.audio.shutdown()
	game.queue_free()
	await settle()
	QAReport.write("res://builds/qa/touch-dash-tests.json", {"checks": checks, "failures": failures, "layouts": 3, "engine_touch_mouse_emulation": true})
	print("TOUCH_DASH_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

extends SceneTree

var checks: int = 0
var failures: Array[String] = []
var pause_events: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func touch(id: int, down: bool, point: Vector2, canceled: bool = false) -> void:
	var event := InputEventScreenTouch.new()
	event.index = id
	event.pressed = down
	event.canceled = canceled
	event.position = root.get_screen_transform() * point
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func drag(id: int, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = id
	event.position = root.get_screen_transform() * point
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func click_resume(game: Node3D) -> void:
	await settle()
	for button in game.ui.root.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and button.text == "RESUME":
			var motion := InputEventMouseMotion.new()
			motion.position = button.get_global_rect().get_center()
			root.push_input(motion, true)
			var event := InputEventMouseButton.new()
			event.position = button.get_global_rect().get_center()
			event.button_index = MOUSE_BUTTON_LEFT
			event.pressed = true
			root.push_input(event, true)
			event = event.duplicate()
			event.pressed = false
			root.push_input(event, true)
			return
	check(false, "resume GUI control exists")

func settle() -> void:
	for i in range(4):
		await process_frame

func frozen(game: Node3D) -> Dictionary:
	return {"position": game.player.position, "time": game.combat.director.elapsed,
		"cooldown": game.player.dash_cooldown, "dash_time": game.player.dash_time,
		"hp": game.player.health.current, "sentry": game.combat.sentry.remaining,
		"save": game.save.data.duplicate(true)}

func run() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.save.path = "user://qa_multitouch_pause.json"
	game.save.data = SaveStore.defaults()
	game.audio.shutdown()
	game.ui.pause_run.connect(func(): pause_events += 1)
	check(Input.emulate_mouse_from_touch, "pause regression uses actual engine mouse-from-touch emulation")
	for size in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(960, 600)]:
		root.size = size
		game.start_run()
		await settle()
		var pause: Vector2 = game.ui.pause_button.get_global_rect().get_center()
		var dash: Vector2 = game.ui.dash_button.get_global_rect().get_center()
		var origin := Vector2(120, game.ui.root.size.y - 120)
		var held := origin + Vector2(75, 0)
		var count: int = pause_events
		touch(7, true, origin)
		drag(7, held)
		game._physics_process(0.05)
		check(game.player.position.x > 0 and game.input_router.movement() == Vector2.RIGHT, "joystick genuinely moves player before pause: %s" % size)
		touch(11, true, pause)
		check(game.state == game.State.PAUSED and pause_events == count + 1, "second finger pauses on down while joystick remains physically held: %s" % size)
		check(game.input_router.touch_id == -1 and game.input_router.stick == Vector2.ZERO and not game.input_router.dash_requested, "pause clears movement ownership and pending dash: %s" % size)
		check(not game.ui.pause_button.input_enabled and not game.ui.dash_button.input_enabled and game.ui.pause_button.touch_id == -1 and game.ui.dash_button.touch_id == -1, "pause transition safely disables/resets both HUD actions during dispatch: %s" % size)
		var state: Dictionary = frozen(game)
		game._physics_process(1.0)
		check(frozen(game) == state, "paused physics cannot advance position/combat/health/dash/sentry/save: %s" % size)
		touch(11, false, pause + Vector2(-250, 0))
		touch(7, false, held)
		check(game.state == game.State.PAUSED and pause_events == count + 1, "touch releases outside cannot resume or double-pause: %s" % size)
		await click_resume(game)
		await settle()
		check(game.state == game.State.PLAYING and game.ui.pause_button.input_enabled and game.ui.dash_button.input_enabled, "actual resume GUI re-enables both HUD actions: %s" % size)
		var at: Vector3 = game.player.position
		game._physics_process(0.01)
		check(game.player.position == at and game.input_router.movement() == Vector2.ZERO and not game.input_router.dash_requested, "resume cannot resurrect walking or deferred dash: %s" % size)

		# A third finger can pause even while both native movement/dash touches exist.
		count = pause_events
		touch(5, true, origin)
		drag(5, held)
		touch(9, true, dash)
		check(game.input_router.dash_requested, "real dash touch is pending before pause arbitration: %s" % size)
		touch(12, true, pause)
		check(game.state == game.State.PAUSED and pause_events == count + 1 and not game.input_router.dash_requested, "pause wins over same-frame pending dash without queued action: %s" % size)
		for item in [[5, held], [9, dash], [12, pause]]:
			touch(item[0], false, item[1])
		await click_resume(game)
		await settle()
		game._physics_process(0.01)
		check(game.player.dash_cooldown == 0 and game.input_router.movement() == Vector2.ZERO, "discarded pre-pause dash cannot launch on resume: %s" % size)

		count = pause_events
		touch(6, true, pause, true)
		touch(6, false, pause, true)
		check(game.state == game.State.PLAYING and pause_events == count, "canceled new touch cannot pause: %s" % size)
		touch(6, true, pause + Vector2(-200, 0))
		drag(6, pause)
		touch(6, false, pause)
		check(game.state == game.State.PLAYING and pause_events == count, "dragging onto pause from outside cannot activate it: %s" % size)

		# Primary (stationary) touch must not get a second activation from mouse emulation.
		touch(0, true, pause)
		check(game.state == game.State.PAUSED and pause_events == count + 1, "primary stationary touch also pauses immediately: %s" % size)
		touch(0, false, pause)
		touch(3, true, pause)
		touch(3, false, pause)
		check(game.state == game.State.PAUSED and pause_events == count + 1, "paused HUD ignores extra touch and emulated-mouse activation: %s" % size)
		await click_resume(game)
		await settle()
		game.progress.pending = 1
		game.show_upgrade()
		touch(3, true, pause)
		touch(3, false, pause)
		check(game.state == game.State.UPGRADING and not game.ui.pause_button.input_enabled and pause_events == count + 1, "upgrade UI cannot accept hidden pause action: %s" % size)
		game.select_upgrade(game.offered[0])
		await settle()
		check(game.state == game.State.PLAYING and game.ui.pause_button.input_enabled, "upgrade completion restores pause action: %s" % size)

		for remaining in [2.5, 0.11, 0.05, 0.049, 0.001, 0.0000001, 0.0]:
			game.player.dash_cooldown = remaining
			var before: Dictionary = frozen(game)
			game.ui.update_hud(game.player, game.progress, game.combat)
			if remaining > 0:
				check(not game.ui.dash_button.text.contains("READY") and not game.ui.dash_button.text.contains("0.0s") and game.ui.dash_gauge.value < 100, "positive dash cooldown never appears ready or zero: %s / %s" % [size, remaining])
			else:
				check(game.ui.dash_button.text == "DASH / READY" and game.ui.dash_gauge.value == 100, "ready dash has exact full gauge and ready text: %s" % size)
			check(frozen(game) == before, "HUD formatting cannot alter any cooldown/physics/progression state")

	# Existing keyboard/controller pause paths still operate independently of touch.
	var key := InputEventKey.new()
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	check(game.state == game.State.PAUSED, "keyboard Escape still pauses")
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	Input.flush_buffered_events()
	game.resume_run()
	await settle()
	var joy := InputEventJoypadButton.new()
	joy.button_index = JOY_BUTTON_START
	joy.pressed = true
	Input.parse_input_event(joy)
	Input.flush_buffered_events()
	check(game.state == game.State.PAUSED, "controller Start still pauses")
	joy = joy.duplicate()
	joy.pressed = false
	Input.parse_input_event(joy)
	Input.flush_buffered_events()
	game.go_menu()
	check(not game.ui.pause_button.input_enabled and not game.ui.dash_button.input_enabled, "menu disables both retained HUD controls")
	game.audio.shutdown()
	game.queue_free()
	await settle()
	QAReport.write("res://builds/qa/touch-pause-tests.json", {"checks": checks, "failures": failures, "layouts": 3, "engine_mouse_emulation": true, "scope": "Actual engine input/GUI and controlled physics; no physical phone latency claim."})
	print("TOUCH_PAUSE_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

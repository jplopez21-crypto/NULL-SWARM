extends SceneTree

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for i in range(4):
		await process_frame

func click(game: Node3D, label: String) -> void:
	for button in game.ui.root.find_children("*", "Button", true, false):
		if not button.is_visible_in_tree() or not button.text.contains(label):
			continue
		var point: Vector2 = button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = point
		root.push_input(motion, true)
		var press := InputEventMouseButton.new()
		press.position = point
		press.button_index = MOUSE_BUTTON_LEFT
		press.button_mask = MOUSE_BUTTON_MASK_LEFT
		press.pressed = true
		root.push_input(press, true)
		var release: InputEventMouseButton = press.duplicate()
		release.pressed = false
		release.button_mask = 0
		root.push_input(release, true)
		return
	check(false, "missing clickable GUI control: " + label)

func retained_until_frame_end(panel: PanelContainer) -> bool:
	return is_instance_valid(panel) and panel.is_inside_tree() and not panel.visible and panel.is_queued_for_deletion()

func run() -> void:
	root.size = Vector2i(1280, 720)
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.save.path = "user://qa_gui_dispatch.json"
	game.save.data = SaveStore.defaults()
	game.audio.shutdown()
	await settle()
	var old_panel: PanelContainer = game.ui.screen
	click(game, "DEPLOY")
	check(game.state == game.State.PLAYING, "real GUI click deploys the operative")
	check(retained_until_frame_end(old_panel), "deploy hides panel without detaching during GUI dispatch")
	await settle()
	check(not is_instance_valid(old_panel), "retired panel is freed at frame end")
	click(game, "PAUSE")
	check(game.state == game.State.PAUSED, "real GUI pause click pauses gameplay")
	await settle()
	old_panel = game.ui.screen
	click(game, "SETTINGS")
	check(retained_until_frame_end(old_panel), "settings transition preserves current dispatch target")
	await settle()
	check(game.ui.screen != null, "settings panel remains usable")
	old_panel = game.ui.screen
	click(game, "BACK")
	check(retained_until_frame_end(old_panel), "back transition safely retires settings panel")
	await settle()
	old_panel = game.ui.screen
	click(game, "RESUME")
	check(game.state == game.State.PLAYING and retained_until_frame_end(old_panel), "resume click safely returns to combat")
	await settle()
	game.go_menu()
	await settle()
	click(game, "PROGRESS BACKUP")
	await settle()
	check(game.ui.screen.find_children("*", "TextEdit", true, false).size() == 1, "backup screen opens through real GUI dispatch")
	var entry: TextEdit = game.ui.screen.find_children("*", "TextEdit", true, false)[0]
	entry.text = game.save.backup_code()
	click(game, "PREVIEW RESTORE")
	await settle()
	check(not game.pending_backup_code.is_empty(), "valid backup opens confirmation through touchable preview control")
	click(game, "CANCEL")
	await settle()
	check(game.pending_backup_code.is_empty(), "cancel discards pending restore without applying")
	entry = game.ui.screen.find_children("*", "TextEdit", true, false)[0]
	entry.text = game.save.backup_code()
	click(game, "PREVIEW RESTORE")
	await settle()
	click(game, "RESTORE THIS BACKUP")
	await settle()
	check(game.pending_backup_code.is_empty() and FileAccess.file_exists(game.save.path + ".pre-import"), "confirmed GUI restore keeps recovery copy")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	QAReport.write("res://builds/qa/gui-input-tests.json", {"checks": checks, "failures": failures})
	print("GUI_INPUT_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

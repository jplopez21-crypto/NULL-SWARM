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
	click(game, "Performance stats")
	await settle()
	check(game.save.data["settings"]["performance_stats"] and game.ui.perf_label.visible and game.save._read(game.save.path)["settings"]["performance_stats"], "GUI diagnostic toggle applies and saves its boolean preference")
	var shortcut := InputEventKey.new()
	shortcut.keycode = KEY_F3
	shortcut.physical_keycode = KEY_F3
	shortcut.pressed = true
	root.push_input(shortcut, true)
	check(not game.save.data["settings"]["performance_stats"] and not game.ui.perf_toggle.button_pressed, "F3 updates saved preference and visible settings control")
	shortcut.echo = true
	root.push_input(shortcut, true)
	check(not game.save.data["settings"]["performance_stats"], "held F3 repeat cannot toggle diagnostics repeatedly")
	shortcut.echo = false
	root.push_input(shortcut, true)
	check(game.save.data["settings"]["performance_stats"] and game.ui.perf_toggle.button_pressed, "F3 can re-enable the same touch preference")
	old_panel = game.ui.screen
	click(game, "BACK")
	check(retained_until_frame_end(old_panel), "back transition safely retires settings panel")
	await settle()
	old_panel = game.ui.screen
	click(game, "RESUME")
	check(game.state == game.State.PLAYING and retained_until_frame_end(old_panel), "resume click safely returns to combat")
	await settle()
	game._process(0)
	check(game.ui.perf_label.is_visible_in_tree() and game.ui.perf_label.text.contains("ENEMIES") and game.ui.perf_label.text.contains("FPS"), "saved diagnostics are visible with real HUD data on resume")
	# A real XP overflow must display and consume every pending choice once.
	game.progress.add_xp(100)
	game.show_upgrade()
	await settle()
	check(game.progress.pending == 3 and game.ui.upgrade_header.text.contains("3 UPGRADES READY"), "XP overflow shows all three pending choices")
	var frozen_clock: float = game.combat.director.elapsed
	game._physics_process(5.0)
	check(game.combat.director.elapsed == frozen_clock, "queued selection keeps combat paused")
	var rerolls_before: int = game.progress.rerolls
	var ranks_before: Dictionary = game.progress.ranks.duplicate()
	click(game, "REROLL")
	await settle()
	check(game.progress.pending == 3 and game.progress.rerolls == rerolls_before - 1 and game.progress.ranks == ranks_before and game.ui.upgrade_header.text.contains("3 UPGRADES READY"), "real reroll changes offers without spending a queued upgrade")
	old_panel = game.ui.screen
	click(game, "01\n")
	check(game.state == game.State.UPGRADING and game.progress.pending == 2 and game.ui.upgrade_header.text.contains("2 UPGRADES READY") and retained_until_frame_end(old_panel), "first queued GUI choice safely advances to two remaining")
	await settle()
	ranks_before = game.progress.ranks.duplicate()
	game.select_upgrade("not-offered")
	check(game.progress.pending == 2 and game.progress.ranks == ranks_before, "invalid selection cannot spend a queued choice")
	click(game, "01\n")
	await settle()
	check(game.state == game.State.UPGRADING and game.progress.pending == 1 and game.ui.upgrade_header.text.contains("1 UPGRADE READY"), "second queued GUI choice shows singular final upgrade")
	var last_choice: String = game.offered[0]
	click(game, "01\n")
	await settle()
	check(game.state == game.State.PLAYING and game.progress.pending == 0, "last queued GUI choice resumes combat")
	ranks_before = game.progress.ranks.duplicate()
	game.select_upgrade(last_choice)
	check(game.progress.pending == 0 and game.progress.ranks == ranks_before, "repeated final selection cannot apply an extra upgrade")
	# A corruption link replaces exactly one of two staged legal level-five choices.
	game.progress.level = 5
	game.progress.pending = 2
	game.show_upgrade()
	await settle()
	var offer_before: Array = game.offered.duplicate()
	var rng_before: int = game.combat.rng.state
	click(game, "UNSTABLE LINK")
	await settle()
	check(game.corruption_panel and game.progress.pending == 2, "opening corruption preserves queued choices")
	click(game, "KEEP MY UPGRADE CHOICES")
	await settle()
	check(game.progress.pending == 2 and game.offered == offer_before and game.combat.rng.state == rng_before and game.ui.upgrade_header.text.contains("2 UPGRADES READY"), "declining corruption restores the same queued offer and count")
	var hull_before: float = game.player.health.maximum
	click(game, "UNSTABLE LINK")
	await settle()
	click(game, CorruptionProtocol.TITLES["redline"])
	await settle()
	check(game.state == game.State.UPGRADING and game.progress.pending == 1 and game.player.health.maximum == hull_before - CorruptionProtocol.HEALTH_COST and game.ui.upgrade_header.text.contains("1 UPGRADE READY"), "accepted corruption consumes exactly one queued choice and applies its cost")
	click(game, "01\n")
	await settle()
	check(game.state == game.State.PLAYING and game.progress.pending == 0, "ordinary choice after corruption completes the queue")
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
	game.change_setting("performance_stats", false)
	click(game, "RESTORE THIS BACKUP")
	await settle()
	check(game.pending_backup_code.is_empty() and FileAccess.file_exists(game.save.path + ".pre-import"), "confirmed GUI restore keeps recovery copy")
	check(game.save.data["settings"]["performance_stats"] and game.ui.perf_label.visible and not game.ui.perf_label.is_visible_in_tree(), "backup restore reapplies saved diagnostics without leaking HUD into menus")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	QAReport.write("res://builds/qa/gui-input-tests.json", {"checks": checks, "failures": failures})
	print("GUI_INPUT_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

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
	game.open_build()
	check(game.state == game.State.PLAYING and game.ui.screen == null, "build view cannot open during active combat")
	click(game, "PAUSE")
	check(game.state == game.State.PAUSED, "real GUI pause click pauses gameplay")
	await settle()
	var frozen_build_clock: float = game.combat.director.elapsed
	var frozen_build_rng: int = game.combat.rng.state
	var frozen_build_save: Dictionary = game.save.data.duplicate(true)
	var frozen_build_ranks: Dictionary = game.progress.ranks.duplicate(true)
	old_panel = game.ui.screen
	click(game, "BUILD // MUTATIONS")
	check(retained_until_frame_end(old_panel), "build transition safely retires pause panel during dispatch")
	await settle()
	var build_text: String = game.ui.visible_build_text()
	check(build_text.contains("WEAPONS 1/4") and build_text.contains("AMPLIFIED PULSE 0/3") and build_text.contains("ARCSTORM RIFLE") and build_text.contains("SOLAR HALO") and build_text.contains("SINGULARITY LANCE"), "actual GUI opens complete current-loadout and mutation guide")
	game._physics_process(10)
	check(game.state == game.State.PAUSED and game.combat.director.elapsed == frozen_build_clock and game.combat.rng.state == frozen_build_rng and game.save.data == frozen_build_save and game.progress.ranks == frozen_build_ranks, "opening guide advances no combat RNG progression or save state")
	old_panel = game.ui.screen
	click(game, "BACK TO PAUSE")
	check(game.state == game.State.PAUSED and retained_until_frame_end(old_panel), "build back returns to pause without resuming")
	await settle()
	check(game.ui.visible_build_text().is_empty(), "retired guide contributes no visible diagnostic text")
	old_panel = game.ui.screen
	click(game, "SETTINGS")
	check(retained_until_frame_end(old_panel), "settings transition preserves current dispatch target")
	await settle()
	check(game.ui.screen != null, "settings panel remains usable")
	var report_time: float = game.combat.director.elapsed
	var report_rng: int = game.combat.rng.state
	var report_save: Dictionary = game.save.data.duplicate(true)
	var old_observations: Array = game.performance_history.samples.duplicate(true)
	click(game, "PERFORMANCE REPORT")
	await settle()
	var report: Dictionary = JSON.parse_string(game.ui.visible_performance_report())
	check(report["status"] == "empty" and not game.ui.performance_report_field.editable and game.ui.performance_report_summary.text == "NO COMBAT OBSERVATIONS YET", "real GUI opens an honest read-only empty performance report")
	game._process(1)
	game._physics_process(1)
	check(game.state == game.State.PAUSED and game.combat.director.elapsed == report_time and game.combat.rng.state == report_rng and game.save.data == report_save and game.performance_history.samples == old_observations, "viewing a paused report cannot sample menu FPS or alter combat RNG or progression")
	if not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		game.copy_performance_report()
		check(game.ui.performance_copy_status.text.contains("not verified"), "unsupported clipboard never claims report-copy success")
	else:
		game.copy_performance_report()
		await settle()
		check(JSON.parse_string(DisplayServer.clipboard_get()) == report and game.ui.performance_copy_status.text == "Report copied.", "supported clipboard receives the actual report data")
	# Explicit fake OS backend: native clipboard execution remains Android coverage.
	var clipboard: Dictionary = {"pending": "", "reads": 0, "writes": 0}
	game.report_clipboard_available = func() -> bool: return true
	game.report_clipboard_write = func(text: String) -> void:
		clipboard["pending"] = text
		clipboard["writes"] += 1
	game.report_clipboard_read = func() -> String:
		clipboard["reads"] += 1
		return clipboard["pending"] if clipboard["reads"] >= 3 else "previous clipboard contents"
	game.copy_performance_report()
	game.copy_performance_report()
	check(game.ui.performance_copy_status.text == "Copying report..." and clipboard["writes"] == 1, "copy waits honestly for readback and coalesces duplicate taps")
	for i in range(6):
		await process_frame
	check(game.ui.performance_copy_status.text == "Report copied." and clipboard["reads"] == 3 and game.report_copy_pending.is_empty() and JSON.parse_string(clipboard["pending"]) == report and not clipboard["pending"].contains("\n"), "delayed clipboard readback preserves complete compact data without blocking or inventing success")
	game.report_clipboard_read = func() -> String: return "blocked clipboard"
	game.copy_performance_report()
	await create_timer(3.2).timeout
	check(game.ui.performance_copy_status.text.contains("not verified") and game.report_copy_pending.is_empty(), "supported but denied clipboard times out without claiming success")
	game.copy_performance_report()
	click(game, "BACK TO SETTINGS")
	await settle()
	check(game.ui.visible_performance_report().is_empty() and game.state == game.State.PAUSED and game.report_copy_pending.is_empty(), "report back cancels pending verification and restores Settings without resuming combat")
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
	# A synthetic legal near-mutation build exercises actual card GUI dispatch.
	game.start_run()
	game.progress.ranks = {"damage": 2, "arc": 3}
	game.combat.weapon.damage += 12.0
	game.combat.update_build(game.progress.ranks)
	game.progress.level = 7
	game.progress.pending = 1
	game.offered.assign(["damage", "speed", "shield"])
	game.state = game.State.UPGRADING
	var preview_rng: int = game.combat.rng.state
	var preview_ranks: Dictionary = game.progress.ranks.duplicate(true)
	var preview_clock: float = game.combat.director.elapsed
	game._render_upgrades()
	await settle()
	var predicted: Button
	for button in game.ui.screen.find_children("*", "Button", true, false):
		if button.text.begins_with("01\n"):
			predicted = button
	check(predicted != null and predicted.text.contains("MUTATES: ARCSTORM RIFLE") and predicted.get_theme_stylebox("normal").border_color == Color("ffe39b") and predicted.get_theme_color("font_focus_color") == Color("ffe39b"), "real finisher card names and highlights the evolved weapon while focused")
	game._physics_process(2.0)
	check(game.progress.ranks == preview_ranks and game.progress.pending == 1 and game.combat.mutations.is_empty() and game.combat.rng.state == preview_rng and game.combat.director.elapsed == preview_clock, "rendering mutation forecasts cannot spend choices, mutate weapons, advance combat or consume RNG")
	click(game, "AMPLIFIED PULSE")
	await settle()
	check(game.state == game.State.PLAYING and game.progress.pending == 0 and game.progress.ranks["damage"] == 3 and game.combat.mutations.has("arcstorm") and game.ui.toast_title.text == "WEAPON MUTATION", "actual forecast pick activates exactly its advertised mutation through normal selection")
	game.progress.pending = 1
	game.state = game.State.UPGRADING
	game.offered.assign(["damage", "speed", "shield"])
	game._render_upgrades()
	await settle()
	var repeated_badge := false
	for button in game.ui.screen.find_children("*", "Button", true, false):
		repeated_badge = repeated_badge or button.text.contains("MUTATES:")
	check(not repeated_badge, "active recipes do not leave a stale mutation badge on future offers")
	var state_before_analysis: int = game.state
	game.open_run_analysis()
	check(game.state == state_before_analysis and game.state != game.State.RESULTS and game.ui.visible_run_analysis().is_empty(), "analysis cannot open before run results")
	game.combat.damage_by_weapon = {"pulse": 50.5, "arcstorm": 25.0, "drone": 24.5}
	game.finish_run(false)
	await settle()
	var analysis_save: Dictionary = game.save.data.duplicate(true)
	var analysis_time: float = game.combat.director.elapsed
	var analysis_rng: int = game.combat.rng.state
	var analysis_ranks: Dictionary = game.progress.ranks.duplicate(true)
	for visit in range(2):
		old_panel = game.ui.screen
		click(game, "RUN ANALYSIS")
		check(retained_until_frame_end(old_panel), "analysis transition preserves the clicked results control during GUI dispatch")
		await settle()
		var analysis_text: String = game.ui.visible_run_analysis()
		check(analysis_text.contains("ARCSTORM RIFLE") and analysis_text.contains("PULSE SHOTS") and analysis_text.contains("ARCSTORM CHAINS") and analysis_text.contains("DRONE SYSTEMS") and analysis_text.contains("50.5%") and analysis_text.contains("25.0%") and analysis_text.contains("24.5%"), "actual analysis control shows build context and every accurately attributed damage share")
		check(analysis_text.contains("Hive and field sentry") and analysis_text.contains("Support, slows and shields"), "analysis explains combined sentry damage and unmeasured utility")
		game._process(5.0)
		game._physics_process(5.0)
		if visit == 0:
			var cancel := InputEventJoypadButton.new()
			cancel.button_index = JOY_BUTTON_B
			cancel.pressed = true
			root.push_input(cancel, true)
		else:
			click(game, "BACK TO RESULTS")
		await settle()
		check(game.ui.visible_run_analysis().is_empty() and game.state == game.State.RESULTS, "analysis back returns to the same completed run")
		check(game.combat.director.elapsed == analysis_time and game.combat.rng.state == analysis_rng and game.save.data == analysis_save and game.progress.ranks == analysis_ranks, "repeated analysis visits advance no time RNG ranks saves or reward ledger")
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
	game.end_deployment()
	check(game.state == game.State.MENU, "end deployment cannot complete a menu without a run")
	game.start_run()
	game.end_deployment()
	check(game.state == game.State.PLAYING and not game.result_aborted, "end deployment requires the deliberate paused action")
	click(game, "PAUSE")
	await settle()
	var end_time: float = game.combat.director.elapsed
	var end_rng: int = game.combat.rng.state
	var end_health: float = game.player.health.current
	var end_runs: int = game.save.data["runs"]
	click(game, "END DEPLOYMENT")
	await settle()
	check(game.state == game.State.RESULTS and game.result_aborted and not game.result_won and game.ui.results_heading.text == "DEPLOYMENT ENDED", "actual paused End Deployment opens honest non-victory results")
	check(game.save.data["runs"] == end_runs + 1 and game.combat.director.elapsed == end_time and game.combat.rng.state == end_rng and game.player.health.current == end_health, "ending records exactly one run without combat time RNG or damage")
	var ended_save: Dictionary = game.save.data.duplicate(true)
	game.end_deployment()
	game.finish_run(false)
	check(game.save.data == ended_save, "repeated end and depletion cannot award or record a completed deployment twice")
	click(game, "RUN ANALYSIS")
	await settle()
	check(not game.ui.visible_run_analysis().is_empty(), "manually ended deployments expose the real analysis control")
	click(game, "BACK TO RESULTS")
	await settle()
	check(game.ui.results_heading.text == "DEPLOYMENT ENDED" and game.save.data == ended_save, "analysis Back preserves voluntary-end wording and ledger")
	click(game, "REDEPLOY")
	await settle()
	check(game.state == game.State.PLAYING and not game.result_aborted, "redeploy clears voluntary-end reason")
	game.finish_run(false)
	await settle()
	check(game.ui.results_heading.text == "SIGNAL LOST", "subsequent actual defeat keeps its death wording")
	game.start_run()
	game.finish_run(true)
	await settle()
	check(game.ui.results_heading.text == "EXTRACTION COMPLETE" and game.result_won and not game.result_aborted, "subsequent victory keeps its extraction wording")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	QAReport.write("res://builds/qa/gui-input-tests.json", {"checks": checks, "failures": failures})
	print("GUI_INPUT_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

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
	if game.ui.boss_cue_label.is_visible_in_tree():
		check(bounds.encloses(game.ui.boss_cue_label.get_global_rect()), "%s %s: boss cue fits viewport" % [size, stage])
	if game.ui.perf_label.is_visible_in_tree():
		check(bounds.encloses(game.ui.perf_label.get_global_rect()), "%s %s: performance stats fit viewport" % [size, stage])
	if game.ui.sentry_label.is_visible_in_tree():
		check(bounds.encloses(game.ui.sentry_label.get_global_rect()), "%s %s: sentry status fits viewport" % [size, stage])
	if game.ui.surge_gauge.is_visible_in_tree():
		check(bounds.encloses(game.ui.surge_label.get_global_rect()), "%s %s: chain feedback fits viewport" % [size, stage])
		check(game.ui.surge_label.get_global_rect().encloses(game.ui.surge_gauge.get_global_rect()), "%s %s: reward gauge fits its HUD row" % [size, stage])
		check(game.ui.surge_gauge.position.y >= game.ui.surge_label.get_line_height(), "%s %s: gauge stays below reward text" % [size, stage])
	if is_instance_valid(game.ui.upgrade_header) and game.ui.upgrade_header.is_visible_in_tree():
		check(bounds.encloses(game.ui.upgrade_header.get_global_rect()), "%s %s: upgrade queue heading fits viewport" % [size, stage])
	var buttons: int = 0
	for node in game.ui.root.find_children("*", "Button", true, false):
		if node.is_visible_in_tree():
			buttons += 1
			check(bounds.encloses(node.get_global_rect()), "%s %s: button outside viewport: %s" % [size, stage, node.text])
			check(node.size.y >= 55.0, "%s %s: undersized button" % [size, stage])
	if game.ui.screen != null:
		check(bounds.encloses(game.ui.screen.get_global_rect()), "%s %s: panel outside viewport" % [size, stage])
		if not game.ui.visible_build_text().is_empty():
			for label in game.ui.screen.find_children("*", "Label", true, false):
				check(bounds.encloses(label.get_global_rect()), "%s %s: build label fits viewport: %s" % [size, stage, label.text])
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
	if captures:
		# Dummy headless rendering returns identity for MultiMesh transform reads.
		# Verify the actual uploaded placement only in the rendered capture suite.
		var panel_positions: Dictionary = {}
		for batch_node in game.arena.find_children("DeckPanels*", "MultiMeshInstance3D", true, false):
			var batch: MultiMeshInstance3D = batch_node
			for i in range(batch.multimesh.instance_count):
				panel_positions[batch.multimesh.get_instance_transform(i).origin] = true
		check(panel_positions.size() == 400 and panel_positions.has(Vector3(-47.5, -0.08, -47.5)) and panel_positions.has(Vector3(47.5, -0.08, 47.5)), "rendered deck preserves all 400 tile placements and original extent")
	for size in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1280, 960), Vector2i(960, 600)]:
		root.size = size
		await settle()
		game.go_menu()
		await inspect(game, "menu", size)
		game.open_backup()
		await inspect(game, "backup", size)
		game.preview_backup(game.save.backup_code())
		await inspect(game, "restore-confirmation", size)
		game.go_menu()
		game.ui.show_settings(game.save.data["settings"], func(): game.go_menu())
		await inspect(game, "settings", size)
		game.start_run()
		game.set_physics_process(false)
		game.pickups.drop(Vector3(12, 0, -5), 100)
		game._process(0.3)
		check(game.ui.memory_visible and is_instance_valid(game.ui.memory_packet), "memory cue acquires packet after deployment")
		check(game.ui.hint_label.visible and game.ui.hint_label.text.contains("DASH"), "new run restores movement onboarding")
		await inspect(game, "combat", size)
		check(not game.ui.perf_label.visible, "new default hides diagnostic HUD")
		game.change_setting("performance_stats", true)
		game._process(0)
		check(game.ui.perf_label.is_visible_in_tree() and game.ui.perf_label.text.contains("FPS") and game.ui.perf_label.text.contains("ENEMIES") and game.ui.perf_label.text.contains("ENGINE"), "enabled diagnostics show honest live monitor labels")
		check(game.ui.perf_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "diagnostic label passes touch through")
		await inspect(game, "performance-stats", size)
		game.change_setting("performance_stats", false)
		game._process(0)
		check(not game.ui.perf_label.is_visible_in_tree(), "disabling diagnostics hides the HUD immediately")
		game.progress.add_xp(100)
		game.combat.director.elapsed = 11
		game._process(0)
		check(game.ui.xp_label.text == "MEMORY 16 / 48  //  NEXT LEVEL 05", "HUD shows actual remaining XP after multi-level overflow")
		check(absf(game.ui.xp_bar.value - 100.0 / 3.0) <= game.ui.xp_bar.step * 0.5, "numeric memory readout agrees with progress fill")
		check(game.ui.hint_label.visible and game.ui.hint_label.text.contains("COLLECT BLUE MEMORY"), "onboarding connects collection to upgrades")
		check(game.ui.xp_bar.get_global_rect().encloses(game.ui.xp_label.get_global_rect()), "memory text fits the bar")
		check(game.ui.xp_label.mouse_filter == Control.MOUSE_FILTER_IGNORE and game.ui.xp_bar.mouse_filter == Control.MOUSE_FILTER_IGNORE, "memory readout and backing cannot intercept touch movement")
		await inspect(game, "memory-onboarding", size)
		game.combat.director.elapsed = 22
		game._process(0)
		check(not game.ui.hint_label.visible, "opening guidance clears before charge warning")
		game.progress.level = 1
		game.progress.xp = 0
		game.progress.pending = 0
		game.combat.director.elapsed = 0
		game.player.dash_cooldown = SwarmPlayer.DASH_COOLDOWN
		game._process(0)
		check(is_zero_approx(game.ui.dash_gauge.value), "new dash cooldown starts with empty readiness gauge")
		game.player.dash_cooldown = SwarmPlayer.DASH_COOLDOWN * 0.5
		game._process(0)
		check(is_equal_approx(game.ui.dash_gauge.value, 50), "dash gauge reflects actual cooldown fraction")
		await inspect(game, "dash-cooldown", size)
		game.player.dash_cooldown = 0
		game._process(0)
		check(is_equal_approx(game.ui.dash_gauge.value, 100) and not game.ui.dash_button.disabled, "ready dash keeps touch button enabled")
		game.player.health.shield = 0
		game.player.health.recharge_delay = 5
		game._process(0)
		check(game.ui.defense_label.text.contains("SHIELD DOWN"), "shield-down HUD explains recovery delay")
		await inspect(game, "shield-down", size)
		game.player.health.recharge_delay = 0
		game._process(0)
		check(game.ui.defense_label.text == "SHIELD RECHARGING", "HUD distinguishes active recharge from waiting")
		game.player.health.shield = game.player.health.max_shield
		game._process(0)
		check(game.ui.defense_label.text == "SHIELD ONLINE", "full shield returns to stable ready label")
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
		var saved_ranks: Dictionary = game.progress.ranks.duplicate(true)
		var saved_mutations: Array[String] = game.combat.mutations.duplicate()
		game.open_build()
		check(game.ui.visible_build_text().contains("WEAPONS 1/4"), "initial guide shows starting weapon and empty slots")
		await inspect(game, "build-empty", size)
		game.progress.ranks = {"damage": 2, "arc": 3, "rail": 2, "magnet": 2}
		game.open_build()
		check(game.ui.visible_build_text().contains("AMPLIFIED PULSE 2/3") and game.ui.visible_build_text().contains("2 weapon slots needed / 1 free"), "guide shows partial ranks and insufficient two-weapon slot path")
		await inspect(game, "build-progress", size)
		game.progress.ranks = {"damage": 3, "arc": 3, "rail": 3, "magnet": 3, "drone": 1}
		game.combat.mutations.assign(["arcstorm", "singularity"])
		game.open_build()
		check(game.ui.visible_build_text().contains("WEAPONS 4/4") and game.ui.visible_build_text().contains("SINGULARITY LANCE // ACTIVE") and game.ui.visible_build_text().contains("SOLAR HALO // SLOTS BLOCKED"), "full guide shows active mutations and blocked alternate recipe")
		await inspect(game, "build-active-full", size)
		game.progress.ranks = {"orbit": 3, "thermal": 3, "rail": 1}
		game.combat.mutations.assign(["halo"])
		game.open_build()
		check(game.ui.visible_build_text().contains("SOLAR HALO // ACTIVE") and game.ui.visible_build_text().contains("PLASMA ORBITALS 3/3"), "Halo replaces its weapon title while keeping original recipe names")
		await inspect(game, "build-halo", size)
		game.progress.ranks = saved_ranks
		game.combat.mutations = saved_mutations
		check(game.state == game.State.PAUSED and game.combat.director.elapsed == clock, "all guide states preserve paused combat")
		game.resume_run()
		game._process(0.3)
		check(game.ui.memory_visible and game.input_router.stick == Vector2.ZERO, "resume reacquires cue without stuck movement")
		game.progress.add_xp(100)
		game.show_upgrade()
		game._process(0.1)
		check(not game.ui.memory_visible, "upgrade selection hides memory cue")
		check(game.progress.pending == 3 and game.ui.upgrade_header.text.contains("3 UPGRADES READY"), "real XP overflow displays three ready upgrades")
		await inspect(game, "upgrades", size)
		var before_reroll: int = game.progress.rerolls
		game.reroll_upgrades()
		check(game.progress.pending == 3 and game.progress.rerolls == before_reroll - 1 and game.ui.upgrade_header.text.contains("3 UPGRADES READY"), "reroll preserves queued-upgrade readout")
		game.select_upgrade(game.offered[0])
		check(game.state == game.State.UPGRADING and game.progress.pending == 2 and game.ui.upgrade_header.text.contains("2 UPGRADES READY"), "first upgrade advances queue without resuming")
		await inspect(game, "upgrades-two", size)
		game.select_upgrade(game.offered[0])
		check(game.state == game.State.UPGRADING and game.progress.pending == 1 and game.ui.upgrade_header.text.contains("1 UPGRADE READY"), "final queued card uses singular count")
		await inspect(game, "upgrades-one", size)
		game.select_upgrade(game.offered[0])
		game._process(0.3)
		check(game.state == game.State.PLAYING and game.ui.memory_visible and game.progress.pending == 0, "last queued upgrade returns to guidance")
		game.progress.level = 5
		game.progress.pending = 2
		game.show_upgrade()
		await inspect(game, "unstable_offer", size)
		var saved_offer: Array = game.offered.duplicate()
		var saved_rng: int = game.combat.rng.state
		game.show_corruption()
		await inspect(game, "corruption", size)
		check(game.corruption_panel, "optional corruption panel opens at level five")
		game.return_upgrades()
		check(game.offered == saved_offer and game.combat.rng.state == saved_rng and game.progress.pending == 2 and game.ui.upgrade_header.text.contains("2 UPGRADES READY"), "declining corruption preserves upgrade cards and queue count")
		game.show_corruption()
		game.select_corruption("redline")
		game._process(0.3)
		check(game.state == game.State.UPGRADING and game.progress.pending == 1 and game.player.health.maximum == 80 and game.ui.upgrade_header.text.contains("1 UPGRADE READY"), "accepted link consumes one queued choice and applies its cost")
		await inspect(game, "corruption-queued", size)
		game.select_upgrade(game.offered[0])
		game._process(0.3)
		check(game.state == game.State.PLAYING and game.progress.pending == 0 and game.ui.corruption_label.text.contains("1/3"), "last choice after corruption returns to gameplay and HUD")
		await inspect(game, "corrupted", size)
		var encounters: EncounterDirector = game.combat.encounters
		encounters.mini = encounters._spawn(game.combat, game.player.position, false)
		encounters.mini_spawned = true
		encounters.attack_cooldown = 0
		encounters.tick(0.01, game.combat, game.player)
		game._process(0.1)
		await inspect(game, "boss-barrage", size)
		encounters._clear_warnings()
		encounters.phase = 2
		encounters.mini.hp = encounters.mini.max_hp * 0.5
		encounters.attack_index = 0
		encounters.attack_cooldown = 0
		encounters.tick(0.01, game.combat, game.player)
		game._process(0.1)
		await inspect(game, "boss-impact", size)
		encounters._clear_warnings()
		encounters.mini.exposed_time = 1.2
		game._process(0.1)
		await inspect(game, "boss-exposed", size)
		for fixture in [["chain-start", 1, 3.0, 0.0, 5.0], ["chain-near", 19, 0.8, 0.0, 95.0], ["overclock-full", 20, 3.0, 6.0, 100.0], ["overclock-sustain", 0, 0.0, 3.0, 50.0], ["chain-next-cycle", 25, 2.0, 0.0, 25.0]]:
			game.combat.streak = fixture[1]
			game.combat.streak_time = fixture[2]
			game.combat.overclock = fixture[3]
			game._process(0)
			check(game.ui.surge_gauge.is_visible_in_tree() and is_equal_approx(game.ui.surge_gauge.value, fixture[4]), "chain/bonus gauge reflects actual combat values")
			check(game.ui.surge_label.mouse_filter == Control.MOUSE_FILTER_IGNORE and game.ui.surge_gauge.mouse_filter == Control.MOUSE_FILTER_IGNORE, "reward feedback passes movement input through")
			if fixture[0] == "chain-near":
				check(game.ui.surge_label.text.contains("1 KILL TO OVERCLOCK") and game.ui.surge_label.text.contains("0.8s"), "near-reward hint explains the final kill and gap")
			if fixture[0] == "overclock-sustain":
				check(not game.ui.surge_label.text.contains("CHAIN") and game.ui.surge_label.text.contains("+60%"), "retained bonus is readable after chain expiry")
			if fixture[0] == "chain-next-cycle":
				check(game.ui.surge_label.text.contains("15 KILLS TO OVERCLOCK"), "next cycle counts remaining kills rather than all lifetime kills")
			await inspect(game, fixture[0], size)
		game.combat.streak = 0
		game.combat.streak_time = 0
		game.combat.overclock = 0
		game._process(0)
		check(not game.ui.surge_gauge.visible and game.ui.surge_label.text.is_empty(), "idle feedback clears without leaving a filled gauge")
		game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
		game._process(0.1)
		check(game.state == game.State.PAUSED and not game.ui.memory_visible, "focus loss pauses and hides guidance")
		game.resume_run()
		game.start_run()
		await settle()
		game._process(0.3)
		check(not game.ui.memory_visible and not is_instance_valid(game.ui.memory_packet), "restart clears freed packet reference")
		game.progress.ranks = {"rail": 2, "magnet": 3}
		game.player.magnet += 3 * 1.2
		check(game.upgrade_description("magnet").contains("RANK 3 → 4"), "Tether card shows explicit mutation prerequisite rank")
		game.combat.update_build(game.progress.ranks)
		game.progress.level = 8
		game.progress.pending = 1
		game.show_upgrade()
		game.offered.assign(["rail", "magnet", "health"])
		game._render_upgrades()
		await inspect(game, "singularity-offer", size)
		game.select_upgrade("rail")
		var gravity_target: SwarmEnemy = game.combat.spawn(0, game.player.position + Vector3(4, 0, -3))
		gravity_target.hp = 1000
		game.combat.grid.rebuild(game.combat.enemies)
		game.combat.target = gravity_target
		game.combat._tick_arsenal(0, game.player)
		game.combat.gravity.tick(0.1, game.combat)
		game._process(0.1)
		check(game.combat.gravity.visible and game.ui.weapons_label.text.contains("SINGULARITY LANCE"), "legal rail upgrade activates field and evolved HUD title")
		await inspect(game, "singularity-field", size)
		game.progress.pending = 1
		game.show_upgrade()
		game.offered.assign(["rail", "health", "shield"])
		game._render_upgrades()
		await inspect(game, "singularity-upgrade", size)
		game.finish_run(false)
		game._process(0.1)
		check(not game.ui.memory_visible, "results hide guidance")
		await inspect(game, "results", size)
		game.ui.show_lab(game.save.data, func(): game.go_menu())
		await inspect(game, "foundry", size)
		var saved_progression: Dictionary = game.save.data.duplicate(true)
		game.go_menu()
		game.save.data["architects"] = 1
		game.open_lab()
		game.select_kit("engineer")
		await inspect(game, "foundry-engineer", size)
		game.start_run()
		game._process(0.3)
		check(game.ui.sentry_label.visible and game.ui.sentry_label.text.contains("DASH TO DEPLOY") and game.ui.sentry_label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Engineer HUD explains passive without blocking touch")
		await inspect(game, "engineer-ready", size)
		game.input_router.stick = Vector2.RIGHT
		game.input_router.dash_requested = true
		game._physics_process(1.0 / 60.0)
		game._process(0.1)
		check(game.combat.sentry.visible and game.ui.sentry_label.text.contains("FIELD SENTRY"), "actual Engineer dash shows sentry and lifetime readout")
		await inspect(game, "engineer-sentry", size)
		game.pause_run()
		game.open_build()
		check(game.ui.visible_build_text().contains("ENGINEER // DASH UPLINK") and game.ui.visible_build_text().contains("WEAPONS 2/4"), "Engineer build guide shows passive and actual starting equipment")
		await inspect(game, "engineer-build", size)
		game.run_unlocks.assign(["conductor", "sentinel", "engineer"])
		game.finish_run(true)
		await inspect(game, "results-unlocks", size)
		game.go_menu()
		game.save.data = saved_progression
	game.audio.shutdown()
	game.queue_free()
	await settle()
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute("user://qa_ui_lifecycle.json" + suffix)
	QAReport.write("res://builds/qa/ui-report.json", {"checks": checks, "failures": failures, "layouts": layouts, "captured": captures, "limitations": ["Project KEEP scaling preserves a 1280x720 logical canvas and letterboxes differing window ratios; window sizes are verified separately.", "Desktop/software rendering; does not emulate Android cutouts, lifecycle process death, real multitouch latency or device performance."]})
	print("UI_RESULT checks=", checks, " layouts=", layouts.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

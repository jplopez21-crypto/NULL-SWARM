extends Node3D

const RUN_SECONDS: float = 600.0
enum State { MENU, PLAYING, UPGRADING, PAUSED, RESULTS }
var pending_backup_code: String = ""
var state: State = State.MENU
var input_router := InputRouter.new()
var save := SaveStore.new()
var progress := RunProgression.new()
var combat: CombatWorld
var player: SwarmPlayer
var pickups: PickupSystem
var ui: GameUI
var audio: SwarmAudio
var camera: Camera3D
var arena: Node3D
var run_root: Node3D
var offered: Array[String] = []
var corruption_panel: bool = false
var dash_trail_clock: float = 0.0
var shake: float = 0.0
var result_recorded: bool = false
var boot_smoke: bool = false
var run_token: String = ""
var checkpoint_time: float = 0.0
var run_unlocks: Array[String] = []
var result_won: bool = false

func _ready() -> void:
	input_router.setup()
	save.load_data()
	audio = SwarmAudio.new()
	add_child(audio)
	audio.apply(save.data["settings"])
	_build_arena()
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 29.0
	camera.far = 180.0
	add_child(camera)
	camera.position = Vector3(0, 32, 23)
	camera.look_at(Vector3.ZERO)
	ui = GameUI.new()
	add_child(ui)
	ui.set_performance_stats(bool(save.data["settings"].get("performance_stats", false)))
	ui.input_router = input_router
	ui.world_camera = camera
	ui.deploy.connect(start_run)
	ui.restart.connect(start_run)
	ui.resume_run.connect(resume_run)
	ui.return_menu.connect(go_menu)
	ui.pause_run.connect(pause_run)
	ui.build_requested.connect(open_build)
	ui.dash.connect(func(): input_router.dash_requested = true)
	ui.upgrade_selected.connect(select_upgrade)
	ui.reroll_requested.connect(reroll_upgrades)
	ui.corruption_requested.connect(show_corruption)
	ui.corruption_return.connect(return_upgrades)
	ui.corruption_selected.connect(select_corruption)
	ui.lab_requested.connect(open_lab)
	ui.research_requested.connect(purchase_research)
	ui.kit_selected.connect(select_kit)
	ui.setting_changed.connect(change_setting)
	ui.backup_requested.connect(open_backup)
	ui.backup_export_requested.connect(export_backup)
	ui.backup_preview_requested.connect(preview_backup)
	ui.backup_restore_requested.connect(restore_backup)
	ui.backup_recovery_requested.connect(preview_recovery)
	ui.show_menu(save.data)
	if OS.is_debug_build() and OS.has_feature("android") and ProjectSettings.get_setting("qa/android_runtime_probe", false):
		var probe: Node = load("res://systems/android_qa_probe.gd").new()
		probe.game = self
		add_child(probe)
	if "--capture" in OS.get_cmdline_user_args():
		_capture_session()
	boot_smoke = "--smoke" in OS.get_cmdline_user_args()
	if boot_smoke:
		start_run()

func _build_arena() -> void:
	arena = ReactorArena.new()
	add_child(arena)

func start_run() -> void:
	corruption_panel = false
	ui.set_performance_stats(bool(save.data["settings"].get("performance_stats", false)))
	dash_trail_clock = 0.0
	if run_root != null:
		remove_child(run_root)
		run_root.queue_free()
	input_router.reset()
	progress = RunProgression.new()
	result_recorded = false
	run_unlocks.clear()
	checkpoint_time = 30.0
	run_token = save.begin_run()
	ui.damage_texts.clear()
	run_root = Node3D.new()
	add_child(run_root)
	player = SwarmPlayer.new()
	run_root.add_child(player)
	combat = CombatWorld.new()
	run_root.add_child(combat)
	pickups = PickupSystem.new()
	run_root.add_child(pickups)
	Research.apply(save.data, player, combat, progress)
	ui.operative_title = Research.KITS[save.data["selected_kit"]]["title"]
	combat.enemy_destroyed.connect(func(at: Vector3, amount: int):
		pickups.drop(at, amount)
		if Engine.get_physics_frames() % 3 == 0:
			audio.play("kill"))
	combat.notice.connect(func(title: String, detail: String, color: Color): ui.toast(title, detail, color))
	combat.weapon_fired.connect(_weapon_sound)
	combat.cache_recovered.connect(func():
		pickups.vacuum()
		player.health.current = minf(player.health.maximum, player.health.current + 30.0)
		player.health.shield = player.health.max_shield
		progress.pending += 1
		shake = 0.5
		_checkpoint_progress())
	combat.player_hit.connect(func():
		shake = 0.3
		audio.play("shield" if player.health.last_hull_loss <= 0.0 else "damage"))
	combat.impact.connect(func(at: Vector3, amount: float, critical: bool):
		ui.add_damage(at, amount, critical, int(save.data["settings"]["quality"]) > 0)
		if critical:
			audio.play("hit"))
	player.health.depleted.connect(func(): finish_run(false))
	ui.hide_panel()
	ui.set_hud(true)
	state = State.PLAYING
	ui.toast("%s // LINK ESTABLISHED" % Research.KITS[save.data["selected_kit"]]["title"], "SALVAGE IS BANKED THROUGHOUT YOUR RUN", Color("78f8d4"))
	camera.position = Vector3(0, 32, 23)

func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	player.flash_feedback = save.data["settings"]["flashes"]
	combat.effects_enabled = save.data["settings"]["flashes"]
	combat.effects.flashes = save.data["settings"]["flashes"]
	combat.effects.quality = int(save.data["settings"]["quality"])
	var before_move := player.position
	if player.tick(delta, input_router.movement(), input_router.dash_requested):
		audio.play("dash")
		combat.effects.emit_fx("ring", player.position, player.position, Color("78f8d4"), 1.7)
		dash_trail_clock = 0.0
	input_router.dash_requested = false
	dash_trail_clock -= delta
	if player.dash_time > 0.0 and dash_trail_clock <= 0.0 and before_move.distance_squared_to(player.position) > 0.0001:
		combat.effects.emit_fx("dash", before_move, player.position, Color("78f8d4"), 0.18)
		dash_trail_clock = 0.04
	if combat.tick(delta, player):
		audio.play("fire")
		player.recoil = 1.0
	# Depletion callbacks can change state during combat.tick.
	if state != State.PLAYING:
		return
	progress.add_xp(pickups.tick(delta, player))
	if combat.director.elapsed >= checkpoint_time:
		_checkpoint_progress()
		checkpoint_time = combat.director.elapsed + 30.0
	if combat.director.elapsed >= RUN_SECONDS and combat.encounters.boss_defeated:
		finish_run(true)
	elif progress.pending > 0:
		show_upgrade()
	if boot_smoke and combat.director.elapsed > 4.0:
		print("SCENE_SMOKE_OK enemies=", combat.active_enemies, " projectiles=", combat.active_projectiles)
		boot_smoke = false
		state = State.PAUSED
		audio.shutdown()
		await get_tree().create_timer(0.20).timeout
		get_tree().quit()

func _process(delta: float) -> void:
	if is_instance_valid(player) and state != State.MENU:
		var desired := player.position + Vector3(0, 32, 23)
		camera.position = camera.position.lerp(desired, 1.0 - exp(-delta * 9.0))
		shake = maxf(0.0, shake - delta)
		if save.data["settings"]["shake"] and state == State.PLAYING:
			camera.h_offset = sin(Time.get_ticks_msec() * 0.07) * shake * 0.25
		else:
			camera.h_offset = 0.0
		# Horizontal axis retained at ultrawide ratios, with a minimum visible depth.
		var aspect := get_viewport().get_visible_rect().size.aspect()
		camera.size = maxf(29.0, aspect * 16.0)
		ui.update_hud(player, progress, combat)
		ui.update_memory(delta, pickups, player, state == State.PLAYING)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		change_setting("performance_stats", not bool(save.data["settings"].get("performance_stats", false)))
	if event.is_action_pressed("pause"):
		if state == State.PLAYING:
			pause_run()
		elif state == State.PAUSED:
			resume_run()
	if state == State.PLAYING:
		input_router.handle(event, get_viewport().get_visible_rect().size)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		input_router.reset()
		if state == State.PLAYING:
			pause_run()
		if save != null:
			if is_instance_valid(combat) and not run_token.is_empty() and state in [State.PAUSED, State.UPGRADING, State.PLAYING]:
				_checkpoint_progress()
			else:
				save.persist()

func pause_run() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	input_router.reset()
	_checkpoint_progress()
	ui.show_pause(save.data["settings"])

func resume_run() -> void:
	if state != State.PAUSED:
		return
	input_router.reset()
	ui.hide_panel()
	state = State.PLAYING

func open_build() -> void:
	if state != State.PAUSED or not is_instance_valid(combat):
		return
	ui.show_build(progress, combat.mutations, func(): ui.show_pause(save.data["settings"]))

func go_menu() -> void:
	if state in [State.PAUSED, State.UPGRADING, State.PLAYING]:
		_record_result(false)
	state = State.MENU
	input_router.reset()
	if run_root != null:
		remove_child(run_root)
		run_root.queue_free()
		run_root = null
		player = null
	camera.position = Vector3(0, 32, 23)
	camera.h_offset = 0.0
	ui.show_menu(save.data)

func _record_result(won: bool) -> void:
	if result_recorded:
		return
	_checkpoint_progress()
	result_recorded = true
	var error := save.record_run(combat.director.elapsed, combat.kills, won, run_token, _warden_down(), _architect_down())
	if error != OK:
		push_error("Could not save run statistics: " + error_string(error))

func finish_run(won: bool) -> void:
	if state == State.RESULTS:
		return
	state = State.RESULTS
	result_won = won
	input_router.reset()
	_record_result(won)
	show_results()

func show_upgrade() -> void:
	state = State.UPGRADING
	input_router.reset()
	offered = progress.choices(combat.rng)
	audio.play("level", "UI")
	corruption_panel = false
	_render_upgrades()

func _render_upgrades() -> void:
	ui.show_upgrades(offered, upgrade_description, progress.level, progress.rerolls, combat.corruption.available(progress.level), progress.pending)

func show_corruption() -> void:
	if state != State.UPGRADING or progress.pending <= 0 or not combat.corruption.available(progress.level):
		return
	corruption_panel = true
	ui.show_corruption(combat.corruption, player, combat, progress.ranks, progress.level)

func return_upgrades() -> void:
	if state != State.UPGRADING or not corruption_panel:
		return
	corruption_panel = false
	_render_upgrades()

func select_corruption(id: String) -> void:
	if state != State.UPGRADING or not corruption_panel or progress.pending <= 0:
		return
	if id == "redline" and player.health.maximum <= CorruptionProtocol.HEALTH_COST:
		return
	if not combat.corruption.select(id, progress.level, progress.ranks):
		return
	progress.pending -= 1
	if id == "redline":
		player.health.maximum -= CorruptionProtocol.HEALTH_COST
		player.health.current = minf(player.health.current, player.health.maximum)
	player.walk_multiplier = combat.corruption.walk_rate()
	corruption_panel = false
	audio.play("level", "UI")
	ui.toast("CORRUPTION LINKED", CorruptionProtocol.TITLES[id] + " // ACTIVE FOR THIS RUN", Color("efa6ff"))
	if progress.pending > 0:
		show_upgrade()
	else:
		ui.hide_panel()
		state = State.PLAYING

func upgrade_description(id: String) -> String:
	if Arsenal.DATA.has(id):
		var definition: Dictionary = Arsenal.DATA[id]
		var rank: int = int(progress.ranks.get(id, 0))
		var line := "NEW WEAPON // %s" % definition["role"] if rank == 0 else "RANK %d → %d // DMG %d → %d" % [rank, rank + 1, int(definition["damage"] * (1.0 + (rank - 1) * 0.28)), int(definition["damage"] * (1.0 + rank * 0.28))]
		var synergy := ""
		if id in ["orbit", "thermal"]:
			synergy = "\nMUTATION: Orbitals 3 + Thermal 3"
		elif id == "rail":
			synergy = "\nEVOLVE: Singularity Lance\nRail 3 + Tether 3\nPull field; bosses stay anchored."
			if combat.mutations.has("singularity"):
				var current_field: float = definition["damage"] * (1.0 + (rank - 1) * 0.28) * GravityField.PULSE_DAMAGE_FRACTION
				var next_field: float = definition["damage"] * (1.0 + rank * 0.28) * GravityField.PULSE_DAMAGE_FRACTION
				synergy = "\nFIELD %.1f → %.1f / PULSE\n5 PULSES / 1.5s\nBosses/charge lanes anchored." % [current_field, next_field]
		elif id == "arc":
			synergy = "\nMUTATION: Arc 3 + Amplified Pulse 3"
		return "%s\n%s\n\n%s%s" % [Arsenal.equipped_title(id, combat.mutations), line, definition["description"], synergy]
	match id:
		"damage": return "AMPLIFIED PULSE\nDamage %d → %d\nSynergy: Pulse 3 + Arc 3" % [int(combat.weapon.damage), int(combat.weapon.damage + 6)]
		"rate": return "RAPID CYCLER\nCooldown %.2fs → %.2fs\nFaster automatic fire." % [combat.weapon.interval / combat.corruption.cycle_rate(), maxf(0.12, combat.weapon.interval * 0.87) / combat.corruption.cycle_rate()]
		"pierce": return "PHASE ROUNDS\nPierce %d → %d\nPunch through another unit." % [combat.weapon.piercing, combat.weapon.piercing + 1]
		"speed": return "SERVO OVERDRIVE\nSpeed %.1f → %.1f\nOutrun the machine tide." % [player.effective_speed(), (player.speed + 0.65) * player.walk_multiplier]
		"health": return "REINFORCED CHASSIS\nMax HP %d → %d\nAlso restores 25 health." % [int(player.health.maximum), int(player.health.maximum + 20)]
		"shield": return "AEGIS CAPACITOR\nShield %d → %d\nRecharges after 5s unharmed." % [int(player.health.max_shield), int(player.health.max_shield + 12)]
		"magnet": return "MEMORY TETHER\nRANK %d → %d\nAttraction %.1fm → %.1fm\nCollect tech from farther away.\nMUTATION: Rail 3 + Tether 3" % [int(progress.ranks.get("magnet", 0)), int(progress.ranks.get("magnet", 0)) + 1, player.magnet, player.magnet + 1.2]
	return "FIELD REPAIR\nRestore 35 HP\nAll systems fully upgraded."

func select_upgrade(id: String) -> void:
	if state != State.UPGRADING or corruption_panel or not progress.select(id, offered):
		return
	match id:
		"damage": combat.weapon.damage += 6.0
		"rate": combat.weapon.interval = maxf(0.12, combat.weapon.interval * 0.87)
		"pierce": combat.weapon.piercing += 1
		"speed": player.speed += 0.65
		"health":
			player.health.maximum += 20.0
			player.health.current = minf(player.health.maximum, player.health.current + 25.0)
		"shield":
			player.health.max_shield += 12.0
			player.health.shield = minf(player.health.max_shield, player.health.shield + 12.0)
		"magnet": player.magnet += 1.2
		"repair": player.health.current = minf(player.health.maximum, player.health.current + 35.0)
	# Emit the ordinary confirmation first so mutation notices keep priority.
	var selected_title: String = upgrade_description(id).get_slice("\n", 0)
	var confirmation: String = "RANK %d // ACTIVE" % int(progress.ranks.get(id, 1)) if id != "repair" else "REPAIR APPLIED"
	ui.toast("UPGRADE LINKED", selected_title + " // " + confirmation, Arsenal.color(id))
	combat.update_build(progress.ranks)
	combat.effects.emit_fx("uplink", player.position, player.position, Arsenal.color(id), 3.0)
	audio.play("ui", "UI")
	if progress.pending > 0:
		show_upgrade()
	else:
		ui.hide_panel()
		state = State.PLAYING

func change_setting(key: String, value: Variant) -> void:
	save.data["settings"][key] = value
	if key == "performance_stats":
		ui.set_performance_stats(bool(value))
	audio.apply(save.data["settings"])
	var error := save.persist()
	if error != OK:
		push_error("Settings save failed: " + error_string(error))

func _exit_tree() -> void:
	if is_instance_valid(player):
		for connection in player.health.depleted.get_connections():
			player.health.depleted.disconnect(connection["callable"])

func reroll_upgrades() -> void:
	if state != State.UPGRADING or corruption_panel or progress.rerolls <= 0:
		return
	progress.rerolls -= 1
	show_upgrade()

func _weapon_sound(id: String) -> void:
	if id in ["mutation", "overclock"]:
		audio.play("level", "UI")
	else:
		audio.play(id)

func _capture_session() -> void:
	await get_tree().create_timer(1.0).timeout
	DirAccess.make_dir_recursive_absolute("res://builds/screenshots")
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/menu.png")
	open_backup()
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/progress_backup.png")
	preview_backup(save.backup_code())
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/progress_restore.png")
	ui.show_lab(save.data, func(): ui.show_menu(save.data))
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/foundry.png")
	start_run()
	# Isolated, staged locator capture with no artificial combat claims.
	pickups.drop(player.position + Vector3(12, 0, -5), 100)
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/memory_locator.png")
	# Staged defensive feedback: freeze visual samples, then restore the fixture.
	ui.toast_time = 0
	ui.damage_texts.clear()
	var saved_defense := Vector4(player.health.current, player.health.shield, player.health.invulnerable, player.health.recharge_delay)
	var saved_position := player.position
	state = State.PAUSED
	player.flash_feedback = true
	player.health.invulnerable = 0
	player.health.take_damage(8)
	player.tick(0.06, Vector2.ZERO, false)
	ui.update_hud(player, progress, combat)
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/shield_feedback.png")
	player.health.invulnerable = 0
	player.health.shield = 0
	player.health.take_damage(12)
	player.tick(0.06, Vector2.ZERO, false)
	ui.update_hud(player, progress, combat)
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/hull_feedback.png")
	player.health.current = saved_defense.x
	player.health.shield = saved_defense.y
	player.health.invulnerable = 0
	player.hit_feedback_time = 0
	state = State.PLAYING
	input_router.stick = Vector2.RIGHT
	input_router.dash_requested = true
	_physics_process(1.0 / 60.0)
	for i in range(3):
		_physics_process(0.04)
	state = State.PAUSED
	ui.toast_time = 0
	ui.update_hud(player, progress, combat)
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/dash_feedback.png")
	input_router.reset()
	player.position = saved_position
	player.dash_cooldown = 0
	player.dash_time = 0
	player.health.current = saved_defense.x
	player.health.shield = saved_defense.y
	player.health.invulnerable = saved_defense.z
	player.health.recharge_delay = saved_defense.w
	player.tick(0, Vector2.ZERO, false)
	combat.effects.tick(1)
	state = State.PLAYING
	# Freeze a staged feedback sample so short impacts remain inspectable in CI.
	progress.pending = 1
	state = State.UPGRADING
	offered = ["speed"]
	select_upgrade("speed")
	state = State.PAUSED
	combat.effects.tick(0.12)
	for i in range(3):
		var sample := combat.spawn(i, player.position + Vector3(-6 + i * 6, 0, -5))
		sample.hit(1, Vector3.ZERO)
		sample.tick(0.015)
		combat.effects.emit_fx("spark", sample.position + Vector3.UP * sample.visual_scale, sample.position, sample.definition.color.lightened(0.3), 0.65)
	combat.effects.destruction(player.position + Vector3(3, 0, 2), Color("ff9274"), false)
	combat.effects.tick(0.025)
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/feedback.png")
	state = State.PLAYING
	# Automated staged capture for visual QA, not a claim of human gameplay.
	progress.ranks = {"orbit": 3, "thermal": 3, "arc": 3, "damage": 3}
	combat.update_build(progress.ranks)
	combat.rng.seed = 7312026
	for i in range(22):
		var angle := i * TAU / 22
		combat.spawn(i % 5, Vector3(cos(angle), 0, sin(angle)) * 10)
	await get_tree().create_timer(2.0).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/combat.png")
	# Staged presentation QA of the warning and new enemy silhouette.
	combat.director.elapsed = SwarmAdaptation.FIRST_ANALYSIS
	combat.adaptation.elapsed = SwarmAdaptation.FIRST_ANALYSIS
	combat.adaptation.pending = "insulators"
	combat.adaptation.starts_at = combat.adaptation.elapsed + 8.0
	combat.adaptation.changed.emit("warning", "insulators")
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/adaptation_warning.png")
	combat.adaptation.tick(8.1, player.position, combat.damage_by_weapon, false)
	combat.director.elapsed += 8.1
	state = State.PAUSED
	ui.damage_texts.clear()
	ui.toast("INSULATOR FORMATION ACTIVE", "AMBER BRACED CORES // ARC RESISTANCE 20%", Color("ffcf85"))
	for i in range(3):
		combat.spawn(5, Vector3(-5 + i * 5, 0, -4))
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/adaptation_active.png")
	state = State.PLAYING
	progress.level = 5
	progress.pending = 1
	show_upgrade()
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/upgrades.png")
	show_corruption()
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/corruption.png")
	select_corruption("redline")
	await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/corrupted.png")
	ui.hide_panel()
	progress.pending = 0
	state = State.PLAYING
	combat.director.elapsed = EncounterDirector.FINAL_BOSS_TIME
	combat.adaptation.elapsed = EncounterDirector.FINAL_BOSS_TIME
	combat.encounters.mini_spawned = true
	combat.encounters.boss_spawned = true
	combat.encounters.boss = combat.encounters._spawn(combat, player.position, true)
	combat.encounters.boss.position = Vector3(0, 0, -7)
	combat.encounters.boss.hp *= 0.5
	combat.encounters.attack_cooldown = 0.1
	player.health.invulnerable = 2.0
	await get_tree().create_timer(0.7).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/architect.png")
	# Staged pattern snapshots freeze only presentation QA, never normal gameplay.
	state = State.PAUSED
	ui.toast_time = 0.0
	ui.damage_texts.clear()
	combat.encounters.boss.exposed_time = 0
	combat.encounters._clear_warnings()
	combat.encounters.phase = 2
	combat.encounters.attack_index = 1
	combat.encounters.attack_cooldown = 0
	combat.encounters.tick(0.01, combat, player)
	ui.update_hud(player, progress, combat)
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/boss_barrage.png")
	combat.encounters._clear_warnings()
	combat.encounters.attack_index = 0
	combat.encounters.attack_cooldown = 0
	combat.encounters.tick(0.01, combat, player)
	ui.update_hud(player, progress, combat)
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/boss_impact.png")
	combat.encounters._clear_warnings()
	combat.encounters.boss.exposed_time = 1.2
	ui.update_hud(player, progress, combat)
	await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/boss_exposed.png")
	state = State.PLAYING
	combat._damage(combat.encounters.boss, 999999.0)
	finish_run(false)
	await get_tree().create_timer(0.4).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/results.png")
	# New evolution is shown through the real upgrade transaction in a staged fixture.
	start_run()
	progress.ranks = {"rail": 2, "magnet": 3, "arc": 2, "drone": 2}
	player.magnet += 3 * 1.2
	combat.update_build(progress.ranks)
	progress.level = 8
	progress.pending = 1
	show_upgrade()
	offered.assign(["rail", "magnet", "health"])
	_render_upgrades()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/singularity_offer.png")
	select_upgrade("rail")
	state = State.PAUSED
	var field_target: SwarmEnemy
	for i in range(6):
		var angle: float = i * TAU / 6.0
		var sample := combat.spawn(0, Vector3(5 + cos(angle) * 2, 0, -3 + sin(angle) * 2))
		sample.hp = 500
		if i == 0:
			field_target = sample
	combat.grid.rebuild(combat.enemies)
	combat.target = field_target
	combat._tick_arsenal(0, player)
	combat.gravity.tick(0.15, combat)
	ui.toast_time = 0
	ui.damage_texts.clear()
	ui.update_hud(player, progress, combat)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/singularity_field.png")
	progress.pending = 1
	show_upgrade()
	offered.assign(["rail", "shield", "health"])
	_render_upgrades()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/singularity_upgrade.png")
	# Staged onboarding/readout capture; not a normal-play progression trace.
	start_run()
	set_physics_process(false)
	progress.add_xp(100)
	progress.pending = 0
	combat.director.elapsed = 11
	pickups.drop(Vector3(12, 0, -5), 25)
	ui.toast_time = 0
	ui.damage_texts.clear()
	ui.update_hud(player, progress, combat)
	ui.update_memory(0.3, pickups, player, true)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/memory_onboarding.png")
	change_setting("performance_stats", true)
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/performance_stats.png")
	change_setting("performance_stats", false)
	# Restore the three pending choices from this staged 100-XP fixture.
	progress.pending = 3
	show_upgrade()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/upgrade_queue.png")
	# Staged guide captures cover a new and a full mutated build, not earned play.
	state = State.PLAYING
	pause_run()
	open_build()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/build_overview_empty.png")
	progress.ranks = {"damage": 3, "arc": 3, "rail": 3, "magnet": 3, "drone": 1}
	combat.update_build(progress.ranks)
	ui.toast_time = 0
	open_build()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/build_overview.png")
	audio.shutdown()
	get_tree().quit()

func _warden_down() -> bool:
	return is_instance_valid(combat) and combat.encounters.mini != null and not combat.encounters.mini.active

func _architect_down() -> bool:
	return is_instance_valid(combat) and combat.encounters.boss != null and not combat.encounters.boss.active

func _checkpoint_progress() -> void:
	if run_token.is_empty() or result_recorded:
		return
	var before := Research.unlocked(save.data)
	var error := save.checkpoint(run_token, combat.director.elapsed, combat.kills, _warden_down(), _architect_down())
	if error != OK:
		ui.toast("SALVAGE SAVE FAILED", "STORAGE ERROR // " + error_string(error), Color("ff9274"))
		return
	for id in Research.unlocked(save.data):
		if not before.has(id):
			run_unlocks.append(id)
			ui.toast("STARTING KIT UNLOCKED", Research.KITS[id]["title"] + " // AVAILABLE IN THE FOUNDRY", Color("ffe39b"))

func show_results() -> void:
	ui.show_results(result_won, combat.director.elapsed, combat.kills, progress.level, pickups.total_collected, int(save.data["ledger"].get("awarded", 0)), int(save.data["salvage"]), combat.damage_by_weapon, run_unlocks)

func open_lab(message: String = "") -> void:
	if state not in [State.MENU, State.RESULTS]:
		return
	ui.show_lab(save.data, _return_from_lab, message)

func _return_from_lab() -> void:
	if state == State.RESULTS:
		show_results()
	else:
		ui.show_menu(save.data)

func purchase_research(id: String) -> void:
	if state not in [State.MENU, State.RESULTS]:
		return
	var error := save.purchase(id)
	if error == OK:
		audio.play("level", "UI")
	else:
		push_warning("Research purchase failed: " + error_string(error))
	open_lab("RESEARCH SAVED" if error == OK else "RESEARCH NOT SAVED // " + error_string(error))

func select_kit(id: String) -> void:
	if state not in [State.MENU, State.RESULTS]:
		return
	var error := save.choose_kit(id)
	if error == OK:
		audio.play("ui", "UI")
	open_lab("STARTING KIT SAVED" if error == OK else "KIT NOT SAVED // " + error_string(error))

func open_backup() -> void:
	if state != State.MENU:
		return
	pending_backup_code = ""
	ui.show_backup()

func export_backup() -> void:
	if state != State.MENU:
		return
	var code := save.backup_code()
	if code.is_empty():
		ui.show_backup("", "Unable to create a valid backup.")
		return
	DisplayServer.clipboard_set(code)
	ui.show_backup(code, "Backup copied. Keep the code somewhere safe.")

func preview_backup(code: String) -> void:
	if state != State.MENU:
		return
	var imported := SaveStore.inspect_backup(code)
	if imported.is_empty():
		pending_backup_code = ""
		ui.show_backup(code.left(16384), "Invalid or damaged backup. Progress was not changed.")
		return
	pending_backup_code = code.strip_edges()
	ui.show_backup_confirmation(save.data, imported)

func restore_backup() -> void:
	if state != State.MENU or pending_backup_code.is_empty():
		return
	var error := save.restore_backup(pending_backup_code)
	pending_backup_code = ""
	if error != OK:
		ui.show_backup("", "Restore failed. Current progress was kept.")
		return
	audio.apply(save.data["settings"])
	ui.show_backup("", "Progress restored. Previous save kept locally.")
	ui.set_performance_stats(bool(save.data["settings"].get("performance_stats", false)))

func preview_recovery() -> void:
	if state != State.MENU:
		return
	var previous := save._read(save.path + ".pre-import")
	if previous.is_empty():
		ui.show_backup("", "No previous restore is available.")
		return
	var recovery := SaveStore.new()
	recovery.data = previous
	preview_backup(recovery.backup_code())

extends Node3D

const RUN_SECONDS: float = 600.0
enum State { MENU, PLAYING, UPGRADING, PAUSED, RESULTS }
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
var shake: float = 0.0
var result_recorded: bool = false
var boot_smoke: bool = false

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
	ui.input_router = input_router
	ui.world_camera = camera
	ui.deploy.connect(start_run)
	ui.restart.connect(start_run)
	ui.resume_run.connect(resume_run)
	ui.return_menu.connect(go_menu)
	ui.pause_run.connect(pause_run)
	ui.dash.connect(func(): input_router.dash_requested = true)
	ui.upgrade_selected.connect(select_upgrade)
	ui.reroll_requested.connect(reroll_upgrades)
	ui.setting_changed.connect(change_setting)
	ui.show_menu(save.data)
	if "--capture" in OS.get_cmdline_user_args():
		_capture_session()
	boot_smoke = "--smoke" in OS.get_cmdline_user_args()
	if boot_smoke:
		start_run()

func _build_arena() -> void:
	arena = ReactorArena.new()
	add_child(arena)

func start_run() -> void:
	if run_root != null:
		remove_child(run_root)
		run_root.queue_free()
	input_router.reset()
	progress = RunProgression.new()
	result_recorded = false
	ui.damage_texts.clear()
	run_root = Node3D.new()
	add_child(run_root)
	player = SwarmPlayer.new()
	run_root.add_child(player)
	combat = CombatWorld.new()
	run_root.add_child(combat)
	pickups = PickupSystem.new()
	run_root.add_child(pickups)
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
		progress.pending += 1)
	combat.player_hit.connect(func():
		shake = 0.3
		audio.play("damage"))
	combat.impact.connect(func(at: Vector3, amount: float, critical: bool):
		ui.add_damage(at, amount, critical, int(save.data["settings"]["quality"]) > 0))
	player.health.depleted.connect(func(): finish_run(false))
	ui.hide_panel()
	ui.set_hud(true)
	state = State.PLAYING
	ui.toast("LINK ESTABLISHED", "COLLECT MEMORY // BUILD YOUR ARSENAL", Color("78f8d4"))
	camera.position = Vector3(0, 32, 23)

func _physics_process(delta: float) -> void:
	if state != State.PLAYING:
		return
	if player.tick(delta, input_router.movement(), input_router.dash_requested):
		audio.play("dash")
		combat.effects.emit_fx("ring", player.position, player.position, Color("78f8d4"), 1.7)
	input_router.dash_requested = false
	player.flash_feedback = save.data["settings"]["flashes"]
	combat.effects_enabled = save.data["settings"]["flashes"]
	combat.effects.flashes = save.data["settings"]["flashes"]
	combat.effects.quality = int(save.data["settings"]["quality"])
	if combat.tick(delta, player):
		audio.play("fire")
		player.recoil = 1.0
	# Depletion callbacks can change state during combat.tick.
	if state != State.PLAYING:
		return
	progress.add_xp(pickups.tick(delta, player))
	if combat.director.elapsed >= RUN_SECONDS and combat.encounters.boss_defeated:
		finish_run(true)
	elif progress.pending > 0:
		show_upgrade()
	if boot_smoke and combat.director.elapsed > 4.0:
		print("SCENE_SMOKE_OK enemies=", combat.active_enemies, " projectiles=", combat.active_projectiles)
		boot_smoke = false
		state = State.PAUSED
		audio.shutdown()
		await get_tree().create_timer(0.05).timeout
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

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F3:
		ui.perf_label.visible = not ui.perf_label.visible
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
			save.persist()

func pause_run() -> void:
	if state != State.PLAYING:
		return
	state = State.PAUSED
	input_router.reset()
	ui.show_pause(save.data["settings"])

func resume_run() -> void:
	if state != State.PAUSED:
		return
	input_router.reset()
	ui.hide_panel()
	state = State.PLAYING

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
	result_recorded = true
	var error := save.record_run(combat.director.elapsed, combat.kills, won)
	if error != OK:
		push_error("Could not save run statistics: " + error_string(error))

func finish_run(won: bool) -> void:
	if state == State.RESULTS:
		return
	state = State.RESULTS
	input_router.reset()
	_record_result(won)
	ui.show_results(won, combat.director.elapsed, combat.kills, progress.level, pickups.total_collected)

func show_upgrade() -> void:
	state = State.UPGRADING
	input_router.reset()
	offered = progress.choices(combat.rng)
	audio.play("level", "UI")
	ui.show_upgrades(offered, upgrade_description, progress.level, progress.rerolls)

func upgrade_description(id: String) -> String:
	if Arsenal.DATA.has(id):
		var definition: Dictionary = Arsenal.DATA[id]
		var rank: int = int(progress.ranks.get(id, 0))
		var line := "NEW WEAPON // %s" % definition["role"] if rank == 0 else "RANK %d → %d // DMG %d → %d" % [rank, rank + 1, int(definition["damage"] * (1.0 + (rank - 1) * 0.28)), int(definition["damage"] * (1.0 + rank * 0.28))]
		var synergy := ""
		if id in ["orbit", "thermal"]:
			synergy = "\nMUTATION: Orbitals 3 + Thermal 3"
		elif id == "arc":
			synergy = "\nMUTATION: Arc 3 + Amplified Pulse 3"
		return "%s\n%s\n\n%s%s" % [definition["title"], line, definition["description"], synergy]
	match id:
		"damage": return "AMPLIFIED PULSE\nDamage %d → %d\nSynergy: Pulse 3 + Arc 3" % [int(combat.weapon.damage), int(combat.weapon.damage + 6)]
		"rate": return "RAPID CYCLER\nCooldown %.2fs → %.2fs\nFaster automatic fire." % [combat.weapon.interval, maxf(0.12, combat.weapon.interval * 0.87)]
		"pierce": return "PHASE ROUNDS\nPierce %d → %d\nPunch through another unit." % [combat.weapon.piercing, combat.weapon.piercing + 1]
		"speed": return "SERVO OVERDRIVE\nSpeed %.1f → %.1f\nOutrun the machine tide." % [player.speed, player.speed + 0.65]
		"health": return "REINFORCED CHASSIS\nMax HP %d → %d\nAlso restores 25 health." % [int(player.health.maximum), int(player.health.maximum + 20)]
		"shield": return "AEGIS CAPACITOR\nShield %d → %d\nRecharges after 5s unharmed." % [int(player.health.max_shield), int(player.health.max_shield + 12)]
		"magnet": return "MEMORY TETHER\nAttraction %.1fm → %.1fm\nCollect tech from farther away." % [player.magnet, player.magnet + 1.2]
	return "FIELD REPAIR\nRestore 35 HP\nAll systems fully upgraded."

func select_upgrade(id: String) -> void:
	if state != State.UPGRADING or not progress.select(id, offered):
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
	combat.update_build(progress.ranks)
	combat.effects.emit_fx("ring", player.position, player.position, Arsenal.color(id), 3.0)
	audio.play("ui", "UI")
	if progress.pending > 0:
		show_upgrade()
	else:
		ui.hide_panel()
		state = State.PLAYING

func change_setting(key: String, value: Variant) -> void:
	save.data["settings"][key] = value
	audio.apply(save.data["settings"])
	var error := save.persist()
	if error != OK:
		push_error("Settings save failed: " + error_string(error))

func _exit_tree() -> void:
	if is_instance_valid(player):
		for connection in player.health.depleted.get_connections():
			player.health.depleted.disconnect(connection["callable"])

func reroll_upgrades() -> void:
	if state != State.UPGRADING or progress.rerolls <= 0:
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
	start_run()
	# Automated staged capture for visual QA, not a claim of human gameplay.
	progress.ranks = {"orbit": 3, "thermal": 3, "arc": 3, "damage": 3}
	combat.update_build(progress.ranks)
	combat.rng.seed = 7312026
	for i in range(22):
		var angle := i * TAU / 22
		combat.spawn(i % 5, Vector3(cos(angle), 0, sin(angle)) * 10)
	await get_tree().create_timer(2.0).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/combat.png")
	progress.pending = 1
	show_upgrade()
	await get_tree().create_timer(0.5).timeout
	get_viewport().get_texture().get_image().save_png("res://builds/screenshots/upgrades.png")
	audio.shutdown()
	get_tree().quit()

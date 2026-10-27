extends SceneTree

var failures: int = 0
var checks: int = 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var health := HealthComponent.new()
	check(health.take_damage(40), "damage accepted")
	check(health.current == 90 and health.shield == 0, "shield absorbs damage first")
	check(not health.take_damage(40), "invulnerability prevents repeated damage")
	health.tick(6.0)
	check(health.shield > 0, "shield recharges")
	health.take_damage(999)
	check(health.current == 0, "health clamps to zero")
	var progress := RunProgression.new()
	progress.add_xp(100)
	check(progress.level == 4 and progress.xp == 16 and progress.pending == 3, "XP overflow across levels")
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in range(50):
		var choices := progress.choices(rng)
		check(choices.size() == 3 and choices[0] != choices[1] and choices[1] != choices[2] and choices[0] != choices[2], "distinct upgrade choices")
	check(not progress.select("invalid", ["invalid"]), "invalid upgrade rejected")
	var offered := progress.choices(rng)
	check(progress.select(offered[0], offered), "offered upgrade accepted")
	for id in RunProgression.IDS:
		progress.ranks[id] = RunProgression.CAPS[id]
	check(progress.choices(rng) == ["repair"], "capped upgrades offer safe repair")
	var slots := RunProgression.new()
	slots.ranks = {"orbit": 1, "arc": 1, "rail": 1}
	check(slots.equipped() == 4 and not slots.eligible("drone"), "four slots reject fifth weapon")
	check(slots.eligible("arc"), "equipped weapons remain upgradeable at slot limit")
	check(Arsenal.mutation({"damage": 3, "arc": 3}).has("arcstorm"), "Arcstorm prerequisites")
	check(not Arsenal.mutation({"damage": 2, "arc": 3}).has("arcstorm"), "mutation requires both prerequisites")
	check(Arsenal.mutation({"orbit": 3, "thermal": 3}).has("halo"), "Solar Halo prerequisites")
	var weapon := WeaponController.new()
	check(weapon.ready_to_fire(0.0, true), "first weapon shot")
	check(not weapon.ready_to_fire(0.1, true), "cooldown blocks shot")
	check(weapon.ready_to_fire(0.5, true), "cooldown expires")
	check(not weapon.ready_to_fire(1.0, false), "no target means no shot")
	var director := SpawnDirector.new()
	for i in range(36000):
		director.tick(1.0 / 60.0)
	check(absf(director.elapsed - 600.0) < 0.01, "ten-minute spawn schedule")
	check(director.spawned > 500, "schedule supplies escalating pressure")
	var early := SpawnDirector.new()
	check(early.interval() > director.interval(), "spawn rate escalates")
	var store := SaveStore.new()
	store.path = "user://test_progress.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(store.path + suffix)
	store.load_data()
	check(store.data["runs"] == 0, "new save defaults")
	check(store.record_run(120, 50, false) == OK, "save writes successfully")
	check(store.record_run(300, 150, true) == OK, "second save creates backup")
	var reload := SaveStore.new()
	reload.path = store.path
	reload.load_data()
	check(reload.data["runs"] == 2 and reload.data["wins"] == 1, "save round trip")
	var corrupt := FileAccess.open(store.path, FileAccess.WRITE)
	corrupt.store_string("broken")
	corrupt.close()
	reload.load_data()
	check(reload.data["runs"] == 1, "corrupted save recovers backup")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(store.path + suffix)
	# Checkpoint ledger: rewards are monotonic and idempotent across interruptions.
	store.data = SaveStore.defaults()
	var token := store.begin_run()
	check(store.checkpoint(token, 90, 40) == OK, "checkpoint writes salvage")
	check(store.data["salvage"] == 4, "salvage formula rewards time and kills")
	store.checkpoint(token, 90, 40)
	check(store.data["salvage"] == 4 and store.data["salvaged_kills"] == 40, "repeated checkpoint cannot duplicate rewards")
	store.checkpoint(token, 45, 20)
	check(store.data["salvage"] == 4, "older checkpoints do not reverse rewards")
	check(store.checkpoint("wrong-token", 90, 40) != OK, "stale run tokens rejected")
	store.checkpoint(token, 180, 150, true)
	check(Research.unlocked(store.data).has("conductor") and Research.unlocked(store.data).has("sentinel"), "kill and boss milestones unlock starting kits")
	var previous_wallet: int = int(store.data["salvage"])
	store.record_run(180, 150, false, token, true)
	store.record_run(180, 150, false, token, true)
	check(store.data["runs"] == 1 and store.data["salvage"] == previous_wallet, "run settlement is idempotent and defeat keeps salvage")
	reload.load_data()
	check(reload.data["salvage"] == previous_wallet and reload.data["wardens"] == 1, "checkpoint progression survives reload")
	check(store.purchase("chassis") == OK, "affordable research can be purchased")
	check(store.data["research"]["chassis"] == 1 and store.data["salvage"] == previous_wallet - 8, "purchase deducts exact cost")
	store.data["salvage"] = 0
	check(store.purchase("tether") != OK and int(store.data["research"].get("tether", 0)) == 0, "unaffordable research cannot be purchased")
	store.data["salvage"] = 100
	store.purchase("logistics")
	check(store.purchase("logistics") != OK, "research rank cap enforced")
	var saved_path: String = store.path
	store.path = "user://nonexistent-parent/failed-save.json"
	var wallet_before_failure: int = int(store.data["salvage"])
	check(store.purchase("tether") != OK and store.data["salvage"] == wallet_before_failure and int(store.data["research"].get("tether", 0)) == 0, "failed purchase write refunds currency and rank")
	store.path = saved_path
	check(store.choose_kit("conductor") == OK and store.choose_kit("invalid") != OK, "only earned starting kits selectable")
	# Version 1 saves migrate without losing statistics/settings or inventing currency.
	var legacy := {"version": 1, "runs": 3, "kills": 200, "best_time": 120.0, "wins": 1, "settings": SaveStore.defaults()["settings"]}
	var legacy_file := FileAccess.open(store.path, FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy))
	legacy_file.close()
	reload.load_data()
	check(reload.data["version"] == 2 and reload.data["kills"] == 200 and reload.data["salvage"] == 0, "v1 save migrates without free salvage")
	check(Research.unlocked(reload.data).has("conductor"), "legacy lifetime kills qualify for kit unlock")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(store.path + suffix)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.save.path = "user://scene_test_progress.json"
	game.save.data = SaveStore.defaults()
	game.set_process(false)
	game.set_physics_process(false)
	game.start_run()
	game.set_physics_process(false)
	var enemy: SwarmEnemy = game.combat.spawn(1, Vector3(10, 0, 0))
	enemy.windup = 0.3
	enemy.charging = 0.2
	enemy.deactivate()
	enemy.activate(Vector3.ZERO, 1.0)
	check(enemy.windup == 0 and enemy.charging == 0 and enemy.hp == enemy.definition.health, "enemy pool resets combat state")
	enemy.deactivate()
	var shot: SwarmProjectile = game.combat.projectiles[0]
	shot.activate(Vector3.ZERO, Vector3.RIGHT, 27, 18, 22)
	shot.struck.append(9)
	shot.deactivate()
	shot.activate(Vector3.ZERO, Vector3.RIGHT, 27, 18, 22)
	check(shot.struck.is_empty(), "projectile reuse resets hit history")
	shot.deactivate()
	var accounting_victim: SwarmEnemy = game.combat.spawn(0, Vector3(4, 0, 0))
	accounting_victim.hp = 10.0
	game.combat._damage(accounting_victim, 1000.0, Vector3.ZERO, false, "rail")
	check(game.combat.damage_by_weapon.get("rail", 0) == 10.0, "damage totals exclude overkill")
	game.combat._damage(accounting_victim, 1000.0, Vector3.ZERO, false, "rail")
	check(game.combat.damage_by_weapon.get("rail", 0) == 10.0, "dead targets cannot inflate damage totals")
	var exposed: SwarmEnemy = game.combat.spawn(0, Vector3(4, 0, 0))
	exposed.exposed_time = 1.2
	var before_hp: float = exposed.hp
	game.combat._damage(exposed, 8.0)
	check(before_hp - exposed.hp == 10.0, "exposed core takes exactly 25 percent bonus damage")
	exposed.deactivate()
	for id in Arsenal.DATA:
		game.combat.loadout = {id: 1}
		game.combat.timers.clear()
		var victim: SwarmEnemy = game.combat.spawn(0, Vector3(3.2, 0, 0))
		game.combat.grid.rebuild(game.combat.enemies)
		game.combat.target = victim
		game.combat._tick_arsenal(0.0, game.player)
		check(victim.hp < victim.max_hp, "%s weapon damages enemies" % id)
		victim.deactivate()
	var kit_data := SaveStore.defaults()
	kit_data["salvaged_kills"] = 150
	kit_data["selected_kit"] = "conductor"
	kit_data["research"] = {"chassis": 3, "tether": 3, "logistics": 1}
	Research.apply(kit_data, game.player, game.combat, game.progress)
	check(game.player.health.maximum == 100.0 and game.player.magnet == 3.35 and game.progress.rerolls == 3, "bounded research benefits applied to starting kit")
	check(game.combat.weapon.damage == 9.0 and game.progress.ranks["arc"] == 1 and game.progress.equipped() == 2, "Conductor trades rifle damage and a slot for Arc Emitter")
	game.combat.update_build({"damage": 3, "arc": 3})
	game.combat.update_build({"damage": 3, "arc": 3})
	check(game.combat.mutations.count("arcstorm") == 1, "mutation activates exactly once")
	game.combat.streak = 19
	var combo_victim: SwarmEnemy = game.combat.spawn(0, Vector3(3, 0, 0))
	game.combat._damage(combo_victim, 999)
	check(game.combat.overclock > 0, "twentieth chained kill triggers Overclock")
	game.start_run()
	game.set_physics_process(false)
	game.progress.pending = 1
	game.show_upgrade()
	game.reroll_upgrades()
	game.reroll_upgrades()
	game.reroll_upgrades()
	check(game.progress.rerolls == 0 and game.progress.pending == 1, "rerolls limited without consuming level choice")
	game.start_run()
	game.set_physics_process(false)
	game.combat.effects.quality = 0
	for i in range(100):
		game.combat.effects.emit_fx("ring", Vector3.ZERO, Vector3.ZERO, Color.WHITE, 1.0)
	check(game.combat.effects.live.size() <= 40, "low graphics bounds cosmetic effect count")
	game.combat.effects.tick(1.0)
	check(game.combat.effects.pool.size() == 160, "effect pool fully reclaimed")
	game.combat.encounters.mini = game.combat.encounters._spawn(game.combat, Vector3.ZERO, false)
	game.combat.encounters.mini_spawned = true
	game.combat.encounters.attack_cooldown = 0.0
	game.combat.encounters.tick(0.01, game.combat, game.player)
	check(game.combat.encounters.warning_time > 1.0, "boss warning precedes attack")
	game.combat.encounters.tick(1.2, game.combat, game.player)
	var hostile_count: int = 0
	for projectile in game.combat.hostile_projectiles:
		if projectile.active:
			hostile_count += 1
	check(hostile_count > 0, "boss fires after telegraph expires")
	game.combat.encounters.attack_cooldown = 0.0
	game.combat.encounters.tick(0.01, game.combat, game.player)
	game.combat.encounters._clear_warnings()
	check(game.combat.encounters.warning_time == 0.0 and game.combat.encounters.warnings.is_empty(), "encounter cleanup cancels pending attacks")
	game.start_run()
	game.set_physics_process(false)
	game.combat.director.elapsed = 599.99
	game.player.health.invulnerable = 1.0
	game._physics_process(1.0 / 60.0)
	check(game.state == game.State.PLAYING and game.combat.encounters.boss.active, "living Architect prevents timed extraction")
	game.combat._damage(game.combat.encounters.boss, 999999.0)
	game._physics_process(1.0 / 60.0)
	check(game.state == game.State.RESULTS, "defeated Architect permits timed extraction")
	game.start_run()
	game.set_physics_process(false)
	game.pause_run()
	game._physics_process(1.0)
	check(game.combat.director.elapsed == 0, "pause freezes gameplay")
	game.resume_run()
	game.combat.rng.seed = 7312026
	# Integration harness: invulnerability isolates run completion from bot skill.
	# This validates state transitions and simulation, not human survivability.
	for frame in range(40000):
		game.player.health.invulnerable = 1.0
		var angle := frame / 360.0
		game.player.position = Vector3(cos(angle) * 16, 0, sin(angle) * 16)
		if game.state == game.State.UPGRADING:
			game.select_upgrade(game.offered[0])
		game._physics_process(1.0 / 60.0)
		# Test extraction gate by explicitly defeating the final boss after its deadline.
		# This is lifecycle validation, not a survivability/balance claim.
		if game.combat.director.elapsed >= 600.0 and game.combat.encounters.boss != null and game.combat.encounters.boss.active:
			game.combat._damage(game.combat.encounters.boss, 999999.0)
		if game.state == game.State.RESULTS:
			break
	check(game.state == game.State.RESULTS, "ten-minute run reaches results")
	check(game.combat.kills > 0, "automatic weapon destroys enemies")
	check(game.combat.encounters.mini_spawned and game.combat.encounters.boss_spawned, "both encounters spawn")
	check(game.result_recorded, "results persisted once")
	game.start_run()
	game.set_physics_process(false)
	check(game.combat.kills == 0 and game.progress.level == 1, "restart resets run")
	game.player.health.shield = 0
	game.player.health.take_damage(999)
	check(game.state == game.State.RESULTS, "lethal damage reaches results")
	game.audio.shutdown()
	game.queue_free()
	# Let audio-thread playback releases finish before engine shutdown.
	await create_timer(0.05).timeout
	await process_frame
	print("TEST_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

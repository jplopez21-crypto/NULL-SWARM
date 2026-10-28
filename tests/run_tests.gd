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
	var source_save := SaveStore.new()
	source_save.data["salvage"] = 42
	source_save.data["salvaged_kills"] = 180
	source_save.data["research"] = {"chassis": 1}
	source_save.data["selected_kit"] = "conductor"
	source_save.data["settings"]["shake"] = false
	var code := source_save.backup_code()
	var imported := SaveStore.inspect_backup(code)
	check(imported["salvage"] == 42 and imported["selected_kit"] == "conductor" and not imported["settings"]["shake"], "portable backup retains earned progress and settings")
	check(SaveStore.inspect_backup(code + "x").is_empty(), "backup checksum rejects corruption")
	check(SaveStore.inspect_backup("NS1.!!!!." + "0".repeat(64)).is_empty(), "invalid base64 fails without decoding")
	check(SaveStore.inspect_backup("x".repeat(16385)).is_empty(), "oversized backup rejected")
	check(SaveStore.inspect_backup("NS2.x.y").is_empty(), "unknown backup version rejected")
	var invalid_save := source_save.data.duplicate(true)
	invalid_save["version"] = 99
	var invalid_text := JSON.stringify(invalid_save)
	check(SaveStore.inspect_backup("NS1." + Marshalls.raw_to_base64(invalid_text.to_utf8_buffer()) + "." + invalid_text.sha256_text()).is_empty(), "future save schema rejected")
	var receiver := SaveStore.new()
	receiver.path = "user://backup_restore_test.json"
	receiver.data["salvage"] = 7
	check(receiver.persist() == OK and receiver.restore_backup(code) == OK, "valid backup restores to disk")
	check(receiver._read(receiver.path)["salvage"] == 42 and receiver._read(receiver.path + ".pre-import")["salvage"] == 7, "restore preserves previous save and writes replacement")
	check(receiver.restore_backup(code) == OK and receiver.data["salvage"] == 42, "repeated restores replace rather than add currency")
	var before_restore := receiver.data.duplicate(true)
	check(receiver.restore_backup("broken") != OK and receiver.data == before_restore, "invalid restore leaves current data unchanged")
	receiver.path = "user://nonexistent_backup_directory/save.json"
	check(receiver.restore_backup(code) != OK and receiver.data == before_restore, "write failure leaves in-memory progress untouched")
	var active_save := SaveStore.new()
	active_save.begin_run()
	check(SaveStore.inspect_backup(active_save.backup_code())["ledger"].is_empty(), "portable backup cannot resume or replay an active reward ledger")
	# Compare the optimized selector against the previous query-based algorithm.
	var spatial := SpatialGrid.new()
	var targets: Array = []
	var targeting_rng := RandomNumberGenerator.new()
	targeting_rng.seed = 91827
	for i in range(80):
		var target := SwarmEnemy.new()
		target.index = i
		target.active = i % 7 != 0
		target.position = Vector3(targeting_rng.randf_range(-30, 30), 0, targeting_rng.randf_range(-30, 30))
		targets.append(target)
	spatial.rebuild(targets)
	# Include inactive stale cell entries, as enemies may die between grid rebuilds.
	targets[1].active = false
	for i in range(200):
		var point := Vector3(targeting_rng.randf_range(-35, 35), 0, targeting_rng.randf_range(-35, 35))
		var radius := targeting_rng.randf_range(0, 35)
		var excluded: Array = [i % 80, (i + 1) % 80] if i % 2 == 0 else []
		var expected: Node3D
		var best := radius * radius
		for target in spatial.query(point, radius):
			if excluded.has(target.index):
				continue
			var distance: float = target.position.distance_squared_to(point)
			if distance < best:
				expected = target
				best = distance
		check(spatial.nearest(point, radius, excluded) == expected, "nearest matches legacy ordering, range and exclusions")
	for target in targets:
		target.active = false
	targets[0].active = true
	targets[1].active = true
	targets[0].position = Vector3(1, 0, 0)
	targets[1].position = Vector3(-1, 0, 0)
	spatial.rebuild(targets)
	check(spatial.nearest(Vector3.ZERO, 2) == targets[1], "equal-distance tie keeps ascending cell order")
	check(spatial.nearest(Vector3.ZERO, 2, [1]) == targets[0], "chain exclusion selects next eligible target")
	check(spatial.nearest(Vector3.ZERO, 1) == null, "exact-radius boundary retains legacy strict comparison")
	check(spatial.nearest(Vector3.ZERO, 0) == null, "zero range has no target")
	check(spatial.nearest(Vector3.ZERO, 2, [0, 1]) == null, "all excluded produces no target")
	for target in targets:
		target.free()
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
	# Adaptation responds to measured style, never invisible spawn-rate multipliers.
	var metrics := {"sample_seconds": 45.0, "total_damage": 1000.0, "stationary_share": 0.0, "direct_share": 0.8, "electric_share": 0.1, "close_share": 0.1}
	check(SwarmAdaptation.classify(metrics) == "bulwarks", "direct-fire response")
	metrics["direct_share"] = 0.1
	metrics["electric_share"] = 0.7
	check(SwarmAdaptation.classify(metrics) == "insulators", "electrical response")
	metrics["electric_share"] = 0.1
	metrics["close_share"] = 0.7
	check(SwarmAdaptation.classify(metrics) == "skimmers", "close-range response")
	metrics["direct_share"] = 0.4
	metrics["electric_share"] = 0.4
	metrics["close_share"] = 0.2
	check(SwarmAdaptation.classify(metrics).is_empty(), "mixed combat without a dominant signature causes no forced counter")
	metrics["sample_seconds"] = 1.0
	check(SwarmAdaptation.classify(metrics).is_empty(), "too short an observation window causes no adaptation")
	metrics["sample_seconds"] = 45.0
	metrics["stationary_share"] = 0.8
	check(SwarmAdaptation.classify(metrics) == "siege", "stationary response")
	metrics["total_damage"] = 10.0
	check(SwarmAdaptation.classify(metrics).is_empty(), "too little evidence causes no adaptation")
	var adaptive := SwarmAdaptation.new()
	for second in range(120):
		adaptive.tick(1.0, Vector3(second, 0, 0), {"arc": (second + 1) * 50.0})
		if second == 118:
			check(adaptive.pending.is_empty(), "no adaptation before first two minutes")
	check(adaptive.pending == "insulators" and adaptive.preferred_kind() == -1, "warning precedes effective adaptation")
	for second in range(7):
		adaptive.tick(1.0, Vector3(120 + second, 0, 0), {"arc": 6000.0})
	check(adaptive.preferred_kind() == -1 and adaptive.status().contains("IN 1s"), "full eight-second warning")
	adaptive.tick(1.0, Vector3(128, 0, 0), {"arc": 6000.0})
	check(adaptive.preferred_kind() == 5 and adaptive.bias() == 0.2, "announced adaptation activates with bounded bias")
	for second in range(45):
		adaptive.tick(1.0, Vector3(129 + second, 0, 0), {"arc": 6000.0}, false)
	check(adaptive.active.is_empty() and adaptive.bias() == 0.0, "adaptation expires without permanent escalation")
	adaptive.enabled = false
	check(adaptive.preferred_kind() == -1, "QA disable has no active bias")
	var encounter_gate := EncounterDirector.new()
	check(not encounter_gate.allows_adaptation(175.0) and not encounter_gate.allows_adaptation(190.0) and encounter_gate.allows_adaptation(200.0) and not encounter_gate.allows_adaptation(520.0), "boss introduction windows suppress new adaptations")
	var boss_gate := SwarmAdaptation.new()
	for second in range(120):
		boss_gate.tick(1.0, Vector3.ZERO, {"pulse": (second + 1) * 50.0}, false)
	check(boss_gate.pending.is_empty(), "boss gate suppresses new adaptation warnings")
	check(boss_gate.samples.size() <= 46, "observation window stays bounded")
	var plain_director := SpawnDirector.new()
	var biased_director := SpawnDirector.new()
	var rng_plain := RandomNumberGenerator.new()
	var rng_biased := RandomNumberGenerator.new()
	rng_plain.seed = 414
	rng_biased.seed = 414
	var plain_total: int = 0
	var biased_total: int = 0
	for frame in range(36000):
		plain_total += plain_director.tick(1.0 / 60.0)
		biased_total += biased_director.tick(1.0 / 60.0)
		plain_director.archetype(rng_plain)
		biased_director.archetype(rng_biased, 5, 0.2)
	check(plain_total == biased_total, "adaptation never increases base spawn count")
	check(rng_plain.state == rng_biased.state, "composition selection uses one RNG draw per spawn decision")
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
	# Pickup merge regression: FIFO neighbours may be on opposite sides of the arena.
	var local_pickups := PickupSystem.new()
	var legacy_pickups := LegacyPickupFixture.new()
	root.add_child(local_pickups)
	root.add_child(legacy_pickups)
	for i in range(300):
		var at := Vector3(-40 if i % 2 == 0 else 40, 0, 0)
		local_pickups.drop(at, 5)
		legacy_pickups.drop(at, 5)
	local_pickups.drop(Vector3(-40, 0, 0), 7)
	legacy_pickups.drop(Vector3(-40, 0, 0), 7)
	check(legacy_pickups.max_merge_distance == 80.0, "legacy fixture reproduces cross-arena XP relocation")
	check(local_pickups.max_merge_distance <= PickupSystem.MERGE_RADIUS and local_pickups.items.size() == 300, "local merge stays nearby without increasing clustered pickup count")
	check(local_pickups.outstanding_xp() == 1507 and legacy_pickups.outstanding_xp() == 1507, "merge conserves total XP")
	local_pickups.drop(Vector3(0, 0, 40), 5)
	check(local_pickups.items.size() == 301, "sparse drops retain a separate collectible beyond soft budget")
	local_pickups.drop(Vector3(-40, 0, 0), 100)
	var large_packet: bool = false
	for item in local_pickups.items:
		if int(item["xp"]) >= 100:
			large_packet = item["mesh"].scale.x > 1.0
	check(large_packet, "high-value memory packets are visibly larger")
	local_pickups.vacuum()
	var before_count: int = local_pickups.items.size()
	local_pickups.drop(Vector3(-40, 0, 0), 5)
	check(local_pickups.items.size() == before_count + 1, "fresh XP never merges into an in-flight pickup")
	var collector := SwarmPlayer.new()
	root.add_child(collector)
	local_pickups.vacuum()
	for i in range(240):
		local_pickups.tick(1.0 / 60.0, collector)
	check(local_pickups.items.is_empty() and local_pickups.total_collected == local_pickups.total_dropped, "vacuum collects all merged XP exactly once")
	local_pickups.drop(Vector3.ZERO, 5)
	check(local_pickups.items[0]["mesh"].scale == Vector3.ONE, "reused pickup resets value-dependent size")
	var dropped_before: int = local_pickups.total_dropped
	local_pickups.drop(Vector3.ZERO, 0)
	local_pickups.drop(Vector3.ZERO, -5)
	check(local_pickups.total_dropped == dropped_before, "invalid pickup amounts cannot change XP accounting")
	var hints := PickupSystem.new()
	root.add_child(hints)
	check(hints.memory_target(Vector3.ZERO, 3.0) == null, "empty field has no memory cue")
	hints.drop(Vector3(9, 0, 0), 5)
	hints.drop(Vector3(10, 0, 0), 100)
	var near_packet: MeshInstance3D = hints.items[0]["mesh"]
	var old_packet: MeshInstance3D = hints.items[1]["mesh"]
	check(hints.memory_target(Vector3.ZERO, 3.0) == near_packet, "memory cue chooses nearest stationary packet")
	check(hints.memory_target(Vector3.ZERO, 3.0, old_packet) == old_packet, "memory cue retains similar-distance target without flicker")
	check(hints.memory_target(Vector3(-10, 0, 0), 3.0, old_packet) == old_packet, "locator accepts distant memory without granting it")
	check(hints.memory_target(Vector3(5, 0, 0), 0.0, old_packet) == near_packet, "locator changes target when another is meaningfully closer")
	hints.items[1]["attract"] = true
	check(hints.memory_target(Vector3.ZERO, 3.0, old_packet) == near_packet, "memory cue discards in-flight preferred target")
	check(hints.memory_target(Vector3(8, 0, 0), 3.0) == null, "memory cue hides packets inside attraction radius")
	check(hints.total_collected == 0 and hints.outstanding_xp() == 105 and not hints.items[0]["attract"], "locator cannot collect move or attract XP")
	hints.vacuum()
	check(hints.memory_target(Vector3.ZERO, 3.0) == null, "vacuumed field clears the memory cue")
	hints.queue_free()
	collector.queue_free()
	local_pickups.queue_free()
	legacy_pickups.queue_free()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.save.path = "user://scene_test_progress.json"
	game.save.data = SaveStore.defaults()
	game.set_process(false)
	game.set_physics_process(false)
	game.start_run()
	game.set_physics_process(false)
	for definition in CombatWorld.DEFINITIONS:
		var phases: Dictionary = {}
		for pooled_enemy in game.combat.enemies:
			if pooled_enemy.definition == definition:
				phases[pooled_enemy.think_phase] = true
		check(phases.size() == 6, "%s AI updates span every batch phase" % definition.title)
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
	var insulator: SwarmEnemy = game.combat.spawn(5, Vector3(5, 0, 0))
	var hp_before: float = insulator.hp
	game.combat._damage(insulator, 10.0, Vector3.ZERO, false, "arc")
	check(is_equal_approx(hp_before - insulator.hp, 8.0), "Insulator reduces arc damage by the stated twenty percent")
	hp_before = insulator.hp
	game.combat._damage(insulator, 10.0, Vector3.ZERO, false, "pulse")
	check(is_equal_approx(hp_before - insulator.hp, 10.0), "Insulator does not resist other weapon families")
	insulator.deactivate()
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
	check(Arsenal.mutation({"rail": 3, "magnet": 3}).has("singularity"), "Singularity requires ranked Rail and Tether")
	check(not Arsenal.mutation({"rail": 2, "magnet": 3}).has("singularity") and not Arsenal.mutation({"rail": 3, "magnet": 2}).has("singularity"), "both Singularity prerequisites are mandatory")
	game.start_run()
	game.set_physics_process(false)
	game.combat.update_build({"rail": 3, "magnet": 3})
	game.combat.update_build({"rail": 3, "magnet": 3})
	check(game.combat.mutations.count("singularity") == 1, "Singularity activates only once")
	var gravity_victim: SwarmEnemy = game.combat.spawn(0, Vector3(4.4, 0, 0))
	gravity_victim.hp = 1000
	game.combat.grid.rebuild(game.combat.enemies)
	game.combat.target = gravity_victim
	game.combat._tick_arsenal(0, game.player)
	check(game.combat.gravity.activations == 1 and game.combat.gravity.position == gravity_victim.position, "mutated rail shot creates a field at its target impact")
	gravity_victim.hp = 1000
	var anchored: SwarmEnemy = game.combat.encounters._spawn(game.combat, Vector3.ZERO, false)
	anchored.position = Vector3(1, 0, 0)
	anchored.hp = 1000
	var winding: SwarmEnemy = game.combat.spawn(1, Vector3(-3, 0, 0))
	winding.windup = 0.8
	winding.hp = 1000
	var charging: SwarmEnemy = game.combat.spawn(1, Vector3(-1, 0, 0))
	charging.charging = 0.5
	charging.hp = 1000
	game.combat.grid.rebuild(game.combat.enemies)
	var field: GravityField = game.combat.gravity
	check(field.activate(Vector3.ZERO, 9), "finite positive field activation accepted")
	field.tick(0.15, game.combat)
	check(gravity_victim.hp == 1000 and field.pulses_fired == 0, "field never deals damage before first pulse deadline")
	field.tick(0.15, game.combat)
	check(is_equal_approx(gravity_victim.position.x, 3.5), "field pulls at three metres per second")
	check(gravity_victim.hp == 991 and field.pulses_fired == 1, "first pulse applies exact advertised damage")
	check(anchored.position == Vector3(1, 0, 0) and winding.position == Vector3(-3, 0, 0) and charging.position == Vector3(-1, 0, 0), "bosses and committed wind-up/charge lanes remain anchored")
	check(game.combat.grid.query(gravity_victim.position, 0.05).has(gravity_victim), "pulled enemy stays indexed after crossing a spatial cell")
	var fresh_grid := SpatialGrid.new()
	fresh_grid.rebuild(game.combat.enemies)
	check(game.combat.grid.query(Vector3.ZERO, 10) == fresh_grid.query(Vector3.ZERO, 10), "incremental field reindex preserves fresh-grid traversal order")
	field.tick(1.2, game.combat)
	check(gravity_victim.hp == 955 and anchored.hp == 955 and field.pulses_fired == 5, "full field delivers five pulses including anchored targets")
	check(not field.visible and field.remaining == 0 and gravity_victim.position.is_equal_approx(Vector3.ZERO), "field expires without pull overshoot")
	field.tick(10, game.combat)
	check(gravity_victim.hp == 955 and field.pulses_fired == 5, "expired field cannot keep damaging enemies")
	check(not field.activate(Vector3(INF, 0, 0), 9) and not field.activate(Vector3.ZERO, NAN), "invalid field coordinates and damage are rejected")
	field.activate(Vector3.ZERO, 9)
	field.activate(Vector3(0.5, 0, 0), 9)
	check(field.get_child_count() == 2 and field.position == Vector3(0.5, 0, 0), "refresh replaces one field without allocating more visual nodes")
	var pulses_before_refresh: int = field.pulses_fired
	field.tick(0.2, game.combat)
	field.activate(Vector3(0.5, 0, 0), 9)
	field.tick(0.1, game.combat)
	check(field.pulses_fired == pulses_before_refresh + 1, "rapid field refresh preserves pulse cadence instead of starving damage")
	game.combat.effects_enabled = false
	field.tick(0.1, game.combat)
	check(field.visible and field.core.scale == Vector3.ONE, "reduced effects retain field boundary without core pulsation")
	var paused_remaining: float = field.remaining
	field.tick(NAN, game.combat)
	check(field.remaining == paused_remaining, "non-finite field delta cannot corrupt clocks or positions")
	game.pause_run()
	game._physics_process(0.5)
	check(field.remaining == paused_remaining, "pausing combat freezes the gravity field clock")
	game.resume_run()
	game.start_run()
	game.set_physics_process(false)
	check(game.combat.gravity.remaining == 0 and game.combat.mutations.is_empty(), "new run resets field and mutation state")

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
	# Visual feedback must stay cosmetic, reset with pooling and respect accessibility.
	var feedback_enemy: SwarmEnemy = game.combat.spawn(0, Vector3(4, 0, 0))
	var before_position: Vector3 = feedback_enemy.position
	feedback_enemy.hit(1, Vector3.ZERO)
	feedback_enemy.tick(0.01)
	check(feedback_enemy.body.scale.x > feedback_enemy.body.scale.y and feedback_enemy.position == before_position, "hit recoil changes only visual transform")
	feedback_enemy.tick(0.1)
	check(feedback_enemy.body.scale.is_equal_approx(Vector3.ONE * feedback_enemy.visual_scale) and is_zero_approx(feedback_enemy.body.position.y), "hit recoil fully settles")
	feedback_enemy.hit(1, Vector3.ZERO)
	feedback_enemy.effects_enabled = false
	feedback_enemy.tick(0.01)
	check(feedback_enemy.body.scale.is_equal_approx(Vector3.ONE * feedback_enemy.visual_scale), "reduced flashes suppress hit recoil")
	feedback_enemy.activate(before_position, 1)
	check(feedback_enemy.body.position == Vector3.ZERO and feedback_enemy.body.scale.is_equal_approx(Vector3.ONE * feedback_enemy.visual_scale), "pool reuse resets body pose")
	var feedback: CombatEffects = game.combat.effects
	feedback.flashes = false
	feedback.emit_fx("spark", Vector3.ZERO, Vector3.ZERO, Color.WHITE)
	check(feedback.live.is_empty(), "reduced flashes suppress sharp impact silhouettes")
	feedback.flashes = true
	feedback.emit_fx("spark", Vector3.ZERO, Vector3.ZERO, Color.WHITE)
	check(feedback.live[0]["mesh"].mesh == feedback.impact_mesh, "impacts reuse shared star mesh")
	var first_impact: MeshInstance3D = feedback.live[0]["mesh"]
	check(first_impact.material_override.cull_mode == BaseMaterial3D.CULL_DISABLED, "flat impact silhouette renders from either camera side")
	feedback.emit_fx("spark", Vector3(0, 2, 0), Vector3.ZERO, Color.WHITE)
	check(is_equal_approx(feedback.live[1]["mesh"].position.y, 2.8) and feedback.live[1]["mesh"].material_override == first_impact.material_override, "raised impacts retain height and reuse their cached material")
	feedback.tick(1)
	feedback.emit_fx("uplink", Vector3.ZERO, Vector3.ZERO, Color.WHITE, 3)
	feedback.tick(0.2)
	check(feedback.live[0]["mesh"].position.y > 0.12, "upgrade ring rises while simulation advances")
	feedback.tick(1)
	check(feedback.pool.size() == 160 and feedback.live.is_empty(), "new feedback returns every mesh to pool")
	feedback.flashes = false
	feedback.emit_fx("dash", Vector3.ZERO, Vector3.RIGHT, Color.WHITE, 0.18)
	check(feedback.live.is_empty(), "reduced flashes suppress dash trails")
	feedback.flashes = true
	feedback.emit_fx("dash", Vector3.ZERO, Vector3.RIGHT, Color.WHITE, 0.18)
	var trail: MeshInstance3D = feedback.live[0]["mesh"]
	check(trail.mesh == feedback.beam_mesh and is_equal_approx(trail.scale.z, 1), "dash trail reuses beam geometry across actual movement segment")
	feedback.tick(0.08)
	check(trail.scale.x > 0 and trail.scale.x < 0.18, "dash trail narrows smoothly during its short lifetime")
	feedback.tick(1)
	check(feedback.pool.size() == 160 and feedback.live.is_empty(), "dash trail returns to existing pool")
	game.progress.pending = 1
	game.show_upgrade()
	game.offered.assign(["speed"])
	game.select_upgrade("speed")
	check(game.ui.toast_title.text == "UPGRADE LINKED" and "SERVO OVERDRIVE" in game.ui.toast_detail.text, "upgrade confirmation names the selected passive")
	game.progress.ranks = {"damage": 2, "arc": 3}
	game.combat.update_build(game.progress.ranks)
	game.progress.pending = 1
	game.show_upgrade()
	game.offered.assign(["damage"])
	game.select_upgrade("damage")
	check(game.ui.toast_title.text == "WEAPON MUTATION", "mutation announcement takes priority over ordinary upgrade confirmation")
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
	var encounter: EncounterDirector = game.combat.encounters
	check(encounter.warnings.size() == 13, "phase-one barrage has one ring and twelve shot lanes")
	check(encounter.cue(encounter.mini).contains("BARRAGE"), "HUD names barrage counterplay during warning")
	encounter.mini.position += Vector3(2, 0, 1)
	encounter.tick(0.01, game.combat, game.player)
	check(encounter.warnings[0].position.is_equal_approx(encounter.mini.position + Vector3(0, 0.08, 0)), "moving source carries radial warning ring")
	var lanes_match: bool = true
	for i in range(12):
		lanes_match = lanes_match and encounter.warnings[i + 1].position.is_equal_approx(encounter.mini.position + encounter.radial_direction(i, 12) * 5 + Vector3(0, 0.10, 0))
	check(lanes_match, "every warning lane follows the advertised firing direction")
	game.combat.encounters.tick(1.2, game.combat, game.player)
	var hostile_count: int = 0
	for projectile in game.combat.hostile_projectiles:
		if projectile.active:
			hostile_count += 1
	check(hostile_count > 0, "boss fires after telegraph expires")
	check(hostile_count == 12, "warning lanes do not change phase-one projectile count")
	var directions_match: bool = true
	for i in range(hostile_count):
		directions_match = directions_match and game.combat.hostile_projectiles[i].velocity.normalized().is_equal_approx(encounter.radial_direction(i, 12))
	check(directions_match, "actual barrage velocity matches warning lanes")
	check(encounter.cue(encounter.mini).contains("RECHARGE"), "HUD distinguishes recharge from an active attack")
	encounter.phase = 2
	encounter.mini.hp = encounter.mini.max_hp * 0.5
	encounter.attack_index = 0
	encounter.attack_cooldown = 0
	encounter.tick(0.01, game.combat, game.player)
	check(not encounter.attacking_radial and encounter.warnings.size() == 3 and encounter.cue(encounter.mini).contains("IMPACT"), "phase-two area warning has three circles and explicit escape cue")
	var impact_locations := encounter.locations.duplicate()
	game.player.position += Vector3(4, 0, 0)
	encounter.tick(0.1, game.combat, game.player)
	check(encounter.locations == impact_locations, "locked impact locations do not chase player movement")
	encounter._clear_warnings()
	encounter.mini.exposed_time = 1.2
	check(encounter.cue(encounter.mini).contains("+25% DAMAGE"), "exposed window advertises the existing damage bonus")
	encounter.mini.exposed_time = 0
	var retired_warning := SwarmVisuals.ring(game.combat, 1, Vector3.ZERO, Color.WHITE)
	encounter.warnings.append(retired_warning)
	encounter._clear_warnings()
	check(not retired_warning.visible and retired_warning.is_queued_for_deletion(), "cancelled danger markers hide immediately before deferred disposal")

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
	check(game.combat.director.elapsed == 0 and game.combat.adaptation.elapsed == 0, "pause freezes gameplay and adaptation")
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
	check(game.combat.kills == 0 and game.progress.level == 1 and game.combat.adaptation.history.is_empty(), "restart resets run and learned signature")
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

extends SceneTree

var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)

func offer(game: Node3D, level: int) -> void:
	game.progress.level = level
	game.progress.pending = 1
	game.show_upgrade()
	game.show_corruption()

func run() -> void:
	var protocol := CorruptionProtocol.new()
	check(not protocol.available(-1) and not protocol.available(4) and protocol.available(5), "links unlock at level five")
	check(not protocol.select("unknown", 5, {}) and protocol.next_level == 5, "invalid link cannot advance state")
	check(not protocol.eligible("hive", 5, {}) and not protocol.select("hive", 5, {}), "hive requires equipped drones")
	check(protocol.select("redline", 5, {}), "first valid link accepted")
	check(not protocol.available(9) and protocol.available(10), "accepted link requires five more levels")
	check(not protocol.select("redline", 10, {}), "links cannot stack duplicate benefits or costs")
	check(protocol.select("fracture", 10, {}) and protocol.select("hive", 15, {"drone": 1}), "all three distinct links can be acquired")
	check(protocol.accepted.size() == 3 and not protocol.available(100), "corruption caps at three links")
	check(is_equal_approx(protocol.cycle_rate(), 1.3) and protocol.extra_rounds() == 1 and protocol.extra_drones() == 1, "power modifiers stay bounded")
	check(is_equal_approx(protocol.enemy_pace(), 1.15) and is_equal_approx(protocol.walk_rate(), 0.88), "risk modifiers stay bounded")
	var clean := CorruptionProtocol.new()
	check(clean.cycle_rate() == 1.0 and clean.enemy_pace() == 1.0 and clean.walk_rate() == 1.0 and clean.extra_rounds() == 0 and clean.extra_drones() == 0, "clean run has identity modifiers")
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.save.path = "user://qa_corruption.json"
	game.save.data = SaveStore.defaults()
	game.start_run()
	game.audio.shutdown()
	game.select_corruption("redline")
	check(game.player.health.maximum == 100 and game.combat.corruption.accepted.is_empty(), "playing-state forged selection rejected")
	game.progress.level = 4
	game.progress.pending = 1
	game.show_upgrade()
	game.show_corruption()
	check(not game.corruption_panel, "early dialog cannot open")
	game.progress.level = 5
	game.progress.pending = 2
	game.show_upgrade()
	var offered: Array = game.offered.duplicate()
	var rng_state: int = game.combat.rng.state
	var rerolls: int = game.progress.rerolls
	var saved: Dictionary = game.save.data.duplicate(true)
	game.show_corruption()
	check(game.corruption_panel and game.progress.pending == 2, "preview does not consume upgrade")
	game.reroll_upgrades()
	game.select_upgrade(game.offered[0])
	check(game.offered == offered and game.combat.rng.state == rng_state and game.progress.rerolls == rerolls and game.progress.pending == 2, "stale upgrade/reroll controls cannot change preview state")
	game.return_upgrades()
	check(not game.corruption_panel and game.offered == offered and game.combat.rng.state == rng_state and game.progress.pending == 2, "decline preserves exact offered cards and RNG")
	game.show_corruption()
	game._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var elapsed: float = game.combat.director.elapsed
	game._physics_process(5.0)
	check(game.corruption_panel and game.state == game.State.UPGRADING and game.combat.director.elapsed == elapsed, "backgrounding preview freezes combat and preserves decision")
	game.player.health.current = 35
	game.select_corruption("redline")
	check(game.player.health.maximum == 80 and game.player.health.current == 35 and game.player.health.shield == 30, "redline lowers max HP without healing or changing shield")
	check(game.progress.pending == 1 and game.state == game.State.UPGRADING and not game.corruption_panel, "link consumes one pending upgrade and preserves remaining choice")
	check(game.save.data == saved, "run-local link does not modify progression save")
	var maximum: float = game.player.health.maximum
	game.select_corruption("redline")
	check(game.player.health.maximum == maximum and game.combat.corruption.accepted.size() == 1, "duplicate UI selection cannot reapply health loss")
	game.select_upgrade(game.offered[0])
	check(game.state == game.State.PLAYING, "normal upgrade remains usable after link")
	game.start_run()
	check(game.player.health.maximum == 100 and game.player.walk_multiplier == 1 and game.combat.corruption.accepted.is_empty(), "restart clears all corruption and health cost")
	game.progress.level = 5
	game.progress.pending = 1
	game.show_upgrade()
	game.show_corruption()
	game.player.health.maximum = 20
	game.player.health.current = 20
	game.select_corruption("redline")
	check(game.combat.corruption.accepted.is_empty() and game.progress.pending == 1, "invalid low-health chassis cannot accept lethal max-HP cost")
	game.player.health.maximum = 100
	game.player.health.current = 100
	game.select_corruption("redline")
	check(game.player.health.current == 80 and game.player.health.maximum == 80, "redline caps current HP to new maximum")
	# Direct fixture setup below isolates modifier wiring, not human survivability.
	offer(game, 10)
	game.select_corruption("fracture")
	check(game.combat.corruption.accepted.size() == 2 and game.state == game.State.PLAYING, "second link commits through legal selection")
	var enemy: SwarmEnemy = game.combat.spawn(0, Vector3(10, 0, 0))
	enemy.hp = 10000
	game.combat.weapon.cooldown = 0
	game.combat.tick(1.0 / 60.0, game.player)
	var rounds: int = 0
	for shot in game.combat.projectiles:
		if shot.active:
			rounds += 1
	check(rounds == 2, "fracture actually fires two rifle rounds")
	check(is_equal_approx(enemy.movement_multiplier, 1.15), "fracture affects existing regular enemies")
	var boss: SwarmEnemy = game.combat.encounters._spawn(game.combat, game.player.position, false)
	game.combat.tick(1.0 / 60.0, game.player)
	check(is_equal_approx(game.combat.weapon.cooldown, game.combat.weapon.interval - 1.3 / 60.0), "redline speeds actual rifle cooldown clock")
	check(boss.movement_multiplier == 1.0, "fracture does not accelerate bosses")
	enemy.windup = 0.7
	enemy.tick(0.1)
	check(is_equal_approx(enemy.windup, 0.6), "enemy pace modifier does not shorten warning time")
	var striker: SwarmEnemy = game.combat.spawn(1, Vector3(20, 0, 0))
	striker.movement_multiplier = 1.15
	striker.windup = 0.7
	striker.tick(0.1)
	check(is_equal_approx(striker.telegraph.scale.z * 7.0, 15.0 * 0.55 * 1.15), "charge lane reflects increased corruption travel distance")
	game.progress.ranks["drone"] = 5
	game.combat.update_build(game.progress.ranks)
	offer(game, 15)
	game.select_corruption("hive")
	game.combat.rig.tick(0, game.player.position, game.progress.ranks, false, game.combat.corruption.extra_drones())
	check(game.combat.rig.drone_points.size() == 4, "hive creates fourth drone beyond normal rank-five cap")
	check(is_equal_approx(game.player.effective_speed(), 6.16), "hive applies twelve-percent walking penalty")
	game.player.position = Vector3.ZERO
	game.player.dash_time = 0
	game.player.tick(0.1, Vector2.RIGHT, false)
	check(is_equal_approx(game.player.position.x, 0.616), "walking movement uses corrupted effective speed")
	game.player.position = Vector3.ZERO
	game.player.dash_cooldown = 0
	game.player.tick(0.01, Vector2.RIGHT, true)
	check(is_equal_approx(game.player.position.x, 0.27), "hive preserves normal dash speed")
	var speed_before: float = game.player.effective_speed()
	game.progress.pending = 1
	game.offered.assign(["speed"])
	game.state = game.State.UPGRADING
	game.select_upgrade("speed")
	check(is_equal_approx(game.player.effective_speed(), speed_before + 0.65 * 0.88), "later speed upgrades preserve corruption multiplier")
	check(not game.combat.corruption.available(100), "all linked run cannot reopen more links")
	game._process(0)
	check(game.ui.corruption_bar.value == 100 and game.ui.corruption_label.text.contains("3/3"), "HUD displays full corruption meter")
	game.start_run()
	await process_frame
	check(game.combat.corruption.accepted.is_empty() and game.player.health.maximum == 100 and game.player.effective_speed() == 7, "fresh deployment restores clean stats after all links")
	game.combat.rig.tick(0, Vector3.ZERO, {"drone": 5}, false)
	check(game.combat.rig.drone_points.size() == 3, "clean rank-five build retains three drones")
	game.audio.shutdown()
	game.queue_free()
	await create_timer(0.05).timeout
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute("user://qa_corruption.json" + suffix)
	QAReport.write("res://builds/qa/corruption-tests.json", {"checks": checks, "failures": failures})
	print("CORRUPTION_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

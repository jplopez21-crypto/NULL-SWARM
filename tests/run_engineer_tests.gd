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

func run() -> void:
	var locked := SaveStore.defaults()
	check(not Research.unlocked(locked).has("engineer"), "Engineer is locked for a new player")
	locked["selected_kit"] = "engineer"
	check(SaveStore.validated(locked)["selected_kit"] == "vanguard", "unearned Engineer selection falls back safely")
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	game.save.path = "user://qa_engineer.json"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.audio.shutdown()
	game.save.data = SaveStore.defaults()
	game.start_run()
	check(not game.combat.sentry.enabled and game.combat.sentry.head == null, "Vanguard allocates no sentry model")
	# Exercise the ordinary checkpoint/reward path with explicit boss-reward fixtures.
	check(game.save.checkpoint(game.run_token, 540, 150, true, true) == OK, "boss reward checkpoint persists")
	check(Research.unlocked(game.save.data).has("engineer"), "Architect reward unlocks Engineer without requiring extraction")
	check(game.save.choose_kit("engineer") == OK, "earned Engineer can be selected")
	var restored: Dictionary = SaveStore.inspect_backup(game.save.backup_code())
	check(restored["selected_kit"] == "engineer" and restored["architects"] == 1, "portable backup retains earned Engineer selection")
	game.start_run()
	check(game.player.health.maximum == 80 and game.combat.weapon.damage == 9 and game.combat.weapon.interval == 0.65, "Engineer starts with advertised fragile chassis and weak rifle")
	check(game.progress.ranks == {"drone": 1} and game.progress.equipped() == 2, "Engineer starts with actual Drone Hive and consumes a slot")
	var sentry: FieldSentry = game.combat.sentry
	check(sentry.enabled and not sentry.visible and sentry.activations == 0, "Engineer begins with a ready inactive passive")
	var origin: Vector3 = game.player.position
	game.input_router.stick = Vector2.RIGHT
	game.input_router.dash_requested = true
	game._physics_process(1.0 / 60.0)
	check(sentry.activations == 1 and sentry.visible and sentry.position == origin and game.player.position != origin, "accepted dash leaves sentry at takeoff rather than following the operative")
	check(sentry.remaining > 2.9 and sentry.remaining <= FieldSentry.DURATION, "sentry uses its advertised three-second lifetime")
	game.input_router.dash_requested = true
	game._physics_process(1.0 / 60.0)
	check(sentry.activations == 1, "cooldown-rejected dash cannot redeploy the sentry")
	game.pause_run()
	var remaining: float = sentry.remaining
	game._physics_process(5)
	check(sentry.remaining == remaining, "pause freezes sentry lifetime and firing")
	game.open_build()
	check(game.ui.visible_build_text().contains("ENGINEER // DASH UPLINK"), "build guide explains actual Engineer passive")
	game.resume_run()
	var target: SwarmEnemy = game.combat.spawn(0, origin + Vector3(4, 0, 0))
	target.hp = 1000
	game.combat.grid.rebuild(game.combat.enemies)
	sentry.attack_clock = 0
	sentry.tick(0.01, game.combat)
	check(sentry.shots == 1 and is_equal_approx(target.hp, 983), "sentry deals base Drone Hive damage through real combat")
	check(is_equal_approx(game.combat.damage_by_weapon.get("drone", 0), 17), "sentry contributes to real drone damage attribution")
	sentry.tick(0.1, game.combat)
	check(sentry.shots == 1, "sentry cooldown prevents per-frame fire")
	game.progress.ranks["drone"] = 3
	game.combat.update_build(game.progress.ranks)
	var before: float = target.hp
	sentry.tick(0.5, game.combat)
	check(sentry.shots == 2 and is_equal_approx(before - target.hp, 26.52), "Drone Hive ranks scale sentry damage")
	target.position = sentry.position + Vector3(15, 0, 0)
	game.combat.grid.rebuild(game.combat.enemies)
	sentry.tick(0.6, game.combat)
	check(sentry.shots == 2, "sentry cannot attack beyond its own range")
	var nodes: int = sentry.get_child_count()
	sentry.deploy(Vector3(8, 0, 0))
	sentry.deploy(Vector3(9, 0, 0))
	check(sentry.get_child_count() == nodes and sentry.position == Vector3(9, 0, 0) and sentry.remaining == 3, "redeployment refreshes and repositions the one reusable model")
	check(not sentry.deploy(Vector3(INF, 0, 0)) and sentry.position.is_finite(), "invalid deployment positions are rejected")
	sentry.tick(3.1, game.combat)
	check(sentry.remaining == 0 and not sentry.visible and sentry.shots == 2, "expired sentry hides without a final late shot")
	# Cosmetic presets and accessibility do not change sentry attacks.
	game.progress.ranks["drone"] = 1
	game.combat.update_build(game.progress.ranks)
	target.position = Vector3(4, 0, 0)
	game.combat.grid.rebuild(game.combat.enemies)
	var losses: Array[float] = []
	for quality in [0, 2]:
		game.combat.effects.quality = quality
		game.combat.effects.flashes = false
		sentry.deploy(Vector3.ZERO)
		before = target.hp
		sentry.tick(0.01, game.combat)
		losses.append(before - target.hp)
	check(losses == [17.0, 17.0], "low/high quality and reduced flashes preserve sentry damage")
	game.combat.corruption.select("redline", 5, game.progress.ranks)
	game.combat.overclock = 1
	sentry.attack_clock = 1
	sentry.tick(0.1, game.combat)
	check(is_equal_approx(sentry.attack_clock, 1.0 - 0.1 * 1.6 * 1.3), "sentry uses the same Overclock and Redline cycle bonuses as other weapons")
	game.start_run()
	check(game.combat.sentry.enabled and game.combat.sentry.activations == 0 and game.combat.sentry.shots == 0 and game.combat.sentry.remaining == 0, "redeployment resets all passive state")
	game.save.data["selected_kit"] = "vanguard"
	game.start_run()
	check(not game.combat.sentry.deploy(Vector3.ZERO) and game.combat.sentry.head == null, "other kits cannot deploy or inherit Engineer sentries")
	game.audio.shutdown()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	QAReport.write("res://builds/qa/engineer-tests.json", {"checks": checks, "failures": failures})
	print("ENGINEER_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

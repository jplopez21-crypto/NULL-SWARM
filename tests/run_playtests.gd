extends SceneTree

var failures: Array[String] = []
const DT: float = 1.0 / 60.0
const MAX_SECONDS: float = 720.0

func _initialize() -> void:
	call_deferred("run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _game(seed_value: int, kit: String) -> Node3D:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	game.save.path = "user://qa_bot_%s_%d.json" % [kit, seed_value]
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(game.save.path + suffix)
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.save.data = SaveStore.defaults()
	# Earned-kit fixtures are explicitly identified; no research or combat stats are granted.
	if kit == "conductor":
		game.save.data["salvaged_kills"] = 150
	if kit == "sentinel":
		game.save.data["wardens"] = 1
	game.save.data["selected_kit"] = kit
	game.start_run()
	game.combat.rng.seed = seed_value
	game.audio.shutdown()
	return game

func simulate(seed_value: int, profile: String, kit: String, duration: float = MAX_SECONDS) -> Dictionary:
	var game := _game(seed_value, kit)
	var bot := PlaytestBot.new()
	bot.profile = profile
	var steps: int = 0
	var max_enemies: int = 0
	var max_shots: int = 0
	var first_level: float = -1.0
	var mutation_times: Dictionary = {}
	var samples: Array[float] = []
	var snapshots: Array[Dictionary] = []
	var next_snapshot: float = 60.0
	var wall_start := Time.get_ticks_usec()
	while steps < int(duration / DT) + 1000 and game.state != game.State.RESULTS and game.combat.director.elapsed < duration:
		bot.tick(game, DT)
		var start := Time.get_ticks_usec()
		game._physics_process(DT)
		samples.append(float(Time.get_ticks_usec() - start) / 1000.0)
		steps += 1
		max_enemies = maxi(max_enemies, game.combat.active_enemies)
		max_shots = maxi(max_shots, game.combat.active_projectiles)
		if first_level < 0 and game.progress.level > 1:
			first_level = game.combat.director.elapsed
		for mutation in game.combat.mutations:
			if not mutation_times.has(mutation):
				mutation_times[mutation] = snappedf(game.combat.director.elapsed, 0.01)
		if game.combat.director.elapsed >= next_snapshot:
			snapshots.append({"time": int(next_snapshot), "hp": snappedf(game.player.health.current, 0.01), "level": game.progress.level, "kills": game.combat.kills})
			next_snapshot += 60.0
		_check(is_finite(game.player.position.x) and is_finite(game.player.health.current), "non-finite player state")
		_check(absf(game.player.position.x) <= 47.01 and absf(game.player.position.z) <= 47.01, "movement escaped arena")
		_check(game.progress.equipped() <= Arsenal.MAX_SLOTS, "bot obtained too many weapons")
		_check(game.player.health.current >= 0.0 and game.player.health.current <= game.player.health.maximum, "health escaped valid bounds")
		_check(game.player.health.shield >= 0.0 and game.player.health.shield <= game.player.health.max_shield, "shield escaped valid bounds")
		_check(game.player.dash_cooldown >= 0.0 and int(game.save.data["salvage"]) >= 0, "negative cooldown or wallet")
		if not failures.is_empty():
			break
		# Flush queued nodes/UI tweens regularly, without waiting for simulated real time.
		if steps % 300 == 0:
			await process_frame
	var uncollected_xp: int = 0
	for item in game.pickups.items:
		uncollected_xp += int(item["xp"])
	var last_upgrade: float = 0.0
	var longest_gap: float = 0.0
	for choice in bot.choices:
		if choice["id"] != "reroll":
			longest_gap = maxf(longest_gap, float(choice["at"]) - last_upgrade)
			last_upgrade = float(choice["at"])
	longest_gap = maxf(longest_gap, game.combat.director.elapsed - last_upgrade)
	var completed: bool = game.state == game.State.RESULTS
	var result := {"seed": seed_value, "profile": profile, "kit": kit, "research": {}, "fixture": "new player" if kit == "vanguard" else "earned kit / no research",
		"outcome": "victory" if completed and game.result_won else ("defeat" if completed else "time_limit"),
		"survived_seconds": snappedf(game.combat.director.elapsed, 0.01), "level": game.progress.level, "kills": game.combat.kills,
		"health": snappedf(game.player.health.current, 0.01), "minimum_health": snappedf(minf(bot.minimum_health, game.player.health.current), 0.01), "dashes": bot.dashes,
		"damage_events": bot.damage_events, "first_level_seconds": snappedf(first_level, 0.01), "first_new_weapon_seconds": snappedf(bot.first_new_weapon, 0.01),
		"xp_collected": game.pickups.total_collected, "uncollected_xp": uncollected_xp, "uncollected_pickups": game.pickups.items.size(),
		"longest_upgrade_gap_seconds": snappedf(longest_gap, 0.01), "last_upgrade_seconds": last_upgrade,
		"weapons_and_ranks": game.progress.ranks.duplicate(), "mutations": mutation_times, "damage_by_weapon": game.combat.damage_by_weapon.duplicate(),
		"warden_spawned": game.combat.encounters.mini_spawned, "warden_defeated": game._warden_down(), "architect_spawned": game.combat.encounters.boss_spawned,
		"architect_defeated": game._architect_down(), "max_enemies": max_enemies, "max_projectiles": max_shots,
		"banked_salvage": int(game.save.data["ledger"].get("awarded", 0)), "upgrade_choices": bot.choices, "minute_snapshots": snapshots,
		"simulation_step_p95_ms": QAReport.percentile(samples, 0.95), "wall_seconds": (Time.get_ticks_usec() - wall_start) / 1000000.0}
	if result["outcome"] == "victory":
		_check(result["architect_defeated"] and float(result["survived_seconds"]) >= 600.0, "invalid victory")
	game.audio.shutdown()
	game.queue_free()
	await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute("user://qa_bot_%s_%d.json" % [kit, seed_value] + suffix)
	return result

func fingerprint(result: Dictionary) -> String:
	var clean := result.duplicate(true)
	clean.erase("simulation_step_p95_ms")
	clean.erase("wall_seconds")
	return JSON.stringify(clean).sha256_text()

func run() -> void:
	var report := QAReport.metadata("normal-rules bot playtests")
	report["limitations"] = ["No invulnerability injection, teleporting, forced boss kills or mid-run stat grants.", "Bot uses normal controls, legal upgrades, and normal dash invulnerability.", "Privileged geometric sensors within 16m plus visible artillery markers; not human reaction/skill.", "Small fixed seed sample; bot wins/losses do not establish human balance or fun.", "All profiles share cautious collector movement; this biases damage comparisons against close-range weapons.", "Headless CPU timings exclude rendering and do not predict phone FPS."]
	var cases: Array[Dictionary] = []
	for profile in PlaytestBot.PROFILES:
		for seed_value in [101, 202]:
			var result: Dictionary = await simulate(seed_value, profile, "vanguard")
			cases.append(result)
			print("BOT_CASE ", profile, " seed=", seed_value, " outcome=", result["outcome"], " time=", result["survived_seconds"], " kills=", result["kills"])
	for kit in ["conductor", "sentinel"]:
		cases.append(await simulate(101, "arcstorm" if kit == "conductor" else "halo", kit))
	var repeat_a: Dictionary = await simulate(909, "halo", "vanguard", 90.0)
	var repeat_b: Dictionary = await simulate(909, "halo", "vanguard", 90.0)
	_check(fingerprint(repeat_a) == fingerprint(repeat_b), "seeded bot replay diverged")
	var wins: int = 0
	var defeats: int = 0
	var timeouts: int = 0
	var flags: Array[String] = []
	for result in cases:
		wins += 1 if result["outcome"] == "victory" else 0
		defeats += 1 if result["outcome"] == "defeat" else 0
		timeouts += 1 if result["outcome"] == "time_limit" else 0
		if float(result["longest_upgrade_gap_seconds"]) > 120.0:
			flags.append("%s/%s seed %d: >120s without upgrade; inspect XP collection/bot path before changing balance." % [result["profile"], result["kit"], result["seed"]])
	report["summary"] = {"victories": wins, "defeats": defeats, "timeouts": timeouts, "investigate": flags}
	report["cases"] = cases
	report["deterministic_replay"] = {"seed": 909, "seconds": 90, "matches": fingerprint(repeat_a) == fingerprint(repeat_b), "fingerprint": fingerprint(repeat_a)}
	report["failures"] = failures
	QAReport.write("res://builds/qa/bot-report.json", report)
	var markdown := "# Bot playtests\n\nNormal combat rules; no forced survival or boss kills. Geometric bot, not a human balance verdict.\n\n| Build | Kit | Seed | Outcome | Seconds | Level | Kills | First weapon |\n|---|---|---:|---|---:|---:|---:|---:|\n"
	for result in cases:
		markdown += "| %s | %s | %d | %s | %.1f | %d | %d | %.1fs |\n" % [result["profile"], result["kit"], result["seed"], result["outcome"], result["survived_seconds"], result["level"], result["kills"], result["first_new_weapon_seconds"]]
	for flag in flags:
		markdown += "\n- " + flag + "\n"
	markdown += "\nDeterministic replay: %s. Failures: %d.\n\nFull choices, damage, mutations, health snapshots and limitations are in bot-report.json.\n" % [report["deterministic_replay"]["matches"], failures.size()]
	QAReport.text_file("res://builds/qa/BOT_REPORT.md", markdown)
	print("BOT_REPORT cases=", cases.size(), " failures=", failures.size())
	await create_timer(0.1).timeout
	quit(0 if failures.is_empty() else 1)

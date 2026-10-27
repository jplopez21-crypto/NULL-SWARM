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

func _game(seed_value: int, kit: String, pickup_mode: String = "local") -> Node3D:
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
	if pickup_mode == "legacy":
		game.run_root.remove_child(game.pickups)
		game.pickups.free()
		game.pickups = LegacyPickupFixture.new()
		game.run_root.add_child(game.pickups)
	game.combat.rng.seed = seed_value
	game.audio.shutdown()
	return game

func simulate(seed_value: int, profile: String, kit: String, duration: float = MAX_SECONDS, pickup_mode: String = "local", bot_policy: String = "cautious") -> Dictionary:
	var starting_failures: int = failures.size()
	var game := _game(seed_value, kit, pickup_mode)
	var bot: PlaytestBot = ValueAwareBot.new() if bot_policy == "value_aware" else PlaytestBot.new()
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
		_check(game.pickups.total_dropped == game.pickups.total_collected + game.pickups.outstanding_xp(), "pickup XP was lost or duplicated")
		if pickup_mode == "local":
			_check(game.pickups.max_merge_distance <= PickupSystem.MERGE_RADIUS + 0.001, "pickup merge exceeded local radius")
		_check(game.player.dash_cooldown >= 0.0 and int(game.save.data["salvage"]) >= 0, "negative cooldown or wallet")
		if failures.size() > starting_failures:
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
	var result := {"bot_policy": bot_policy, "pickup_mode": pickup_mode, "pickup_merges": game.pickups.merged_count, "max_merge_distance": game.pickups.max_merge_distance, "peak_pickups": game.pickups.peak_count, "seed": seed_value, "profile": profile, "kit": kit, "research": {}, "fixture": "new player" if kit == "vanguard" else "earned kit / no research",
		"outcome": "victory" if completed and game.result_won else ("defeat" if completed else "time_limit"),
		"survived_seconds": snappedf(game.combat.director.elapsed, 0.01), "level": game.progress.level, "kills": game.combat.kills,
		"health": snappedf(game.player.health.current, 0.01), "minimum_health": snappedf(minf(bot.minimum_health, game.player.health.current), 0.01), "dashes": bot.dashes,
		"damage_events": bot.damage_events, "first_level_seconds": snappedf(first_level, 0.01), "first_new_weapon_seconds": snappedf(bot.first_new_weapon, 0.01),
		"xp_collected": game.pickups.total_collected, "uncollected_xp": uncollected_xp, "uncollected_pickups": game.pickups.items.size(),
		"longest_upgrade_gap_seconds": snappedf(longest_gap, 0.01), "last_upgrade_seconds": last_upgrade,
		"weapons_and_ranks": game.progress.ranks.duplicate(), "mutations": mutation_times, "damage_by_weapon": game.combat.damage_by_weapon.duplicate(),
		"warden_spawned": game.combat.encounters.mini_spawned, "warden_defeated": game._warden_down(), "architect_spawned": game.combat.encounters.boss_spawned,
		"architect_defeated": game._architect_down(), "max_enemies": max_enemies, "max_projectiles": max_shots,
		"adaptations": game.combat.adaptation.history.duplicate(true), "spawned_by_type": game.combat.spawned_by_type.duplicate(), "resisted_hits": game.combat.resisted_hits,
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
	if "--collector-probe" in OS.get_cmdline_user_args():
		var report := QAReport.metadata("upgrade-gap collector investigation")
		var cases: Array[Dictionary] = []
		for profile in ["arcstorm", "kinetic"]:
			for seed_value in [101, 202]:
				for policy in ["cautious", "value_aware"]:
					var result: Dictionary = await simulate(seed_value, profile, "vanguard", MAX_SECONDS, "local", policy)
					cases.append(result)
					print("COLLECTOR_CASE ", profile, " seed=", seed_value, " policy=", policy, " outcome=", result["outcome"], " level=", result["level"], " gap=", result["longest_upgrade_gap_seconds"])
		report["cases"] = cases
		report["failures"] = failures
		report["limitations"] = ["Same normal combat and upgrade policy; only collection navigation differs.", "Two fixed seeds and geometric bots do not establish human pacing or balance."]
		QAReport.write("res://builds/qa/collector-probe.json", report)
		quit(0 if failures.is_empty() else 1)
		return
	if "--adaptation-probe" in OS.get_cmdline_user_args():
		var probe_cases: Array[Dictionary] = []
		for kit in ["vanguard", "conductor"]:
			var probe: Dictionary = await simulate(101, "electric", kit)
			probe_cases.append(probe)
			print("ADAPTATION_PROBE ", kit, " outcome=", probe["outcome"], " resisted_hits=", probe["resisted_hits"])
		QAReport.write("res://builds/qa/adaptation-probe.json", {"cases": probe_cases, "failures": failures})
		quit(0 if failures.is_empty() else 1)
		return
	if "--xp-comparison" in OS.get_cmdline_user_args():
		await compare_pickups()
		return
	var report := QAReport.metadata("normal-rules bot playtests")
	report["limitations"] = ["No invulnerability injection, teleporting, forced boss kills or mid-run stat grants.", "Bot uses normal controls, legal upgrades, and normal dash invulnerability.", "Privileged geometric sensors within 16m plus visible artillery markers; not human reaction/skill.", "Small fixed seed sample; bot wins/losses do not establish human balance or fun.", "All profiles share cautious collector movement; this biases damage comparisons against close-range weapons.", "Headless CPU timings exclude rendering and do not predict phone FPS."]
	var cases: Array[Dictionary] = []
	for profile in PlaytestBot.PROFILES:
		for seed_value in [101, 202]:
			var result: Dictionary = await simulate(seed_value, profile, "vanguard")
			cases.append(result)
			print("BOT_CASE ", profile, " seed=", seed_value, " outcome=", result["outcome"], " time=", result["survived_seconds"], " kills=", result["kills"])
	for kit in ["conductor", "sentinel"]:
		cases.append(await simulate(101, "electric" if kit == "conductor" else "halo", kit))
	var repeat_a: Dictionary = await simulate(909, "halo", "vanguard", 180.0)
	var repeat_b: Dictionary = await simulate(909, "halo", "vanguard", 180.0)
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
	var response_counts: Dictionary = {}
	var resisted: int = 0
	for result in cases:
		resisted += int(result["resisted_hits"])
		for event in result["adaptations"]:
			if event["event"] == "warning":
				response_counts[event["style"]] = int(response_counts.get(event["style"], 0)) + 1
	report["summary"] = {"adaptation_warnings": response_counts, "resisted_hits": resisted, "victories": wins, "defeats": defeats, "timeouts": timeouts, "investigate": flags}
	report["cases"] = cases
	report["deterministic_replay"] = {"seed": 909, "seconds": 180, "matches": fingerprint(repeat_a) == fingerprint(repeat_b), "fingerprint": fingerprint(repeat_a)}
	report["failures"] = failures
	QAReport.write("res://builds/qa/bot-report.json", report)
	var markdown := "# Bot playtests\n\nNormal combat rules; no forced survival or boss kills. Geometric bot, not a human balance verdict.\n\n| Build | Kit | Seed | Outcome | Seconds | Level | Kills | First weapon |\n|---|---|---:|---|---:|---:|---:|---:|\n"
	for result in cases:
		markdown += "| %s | %s | %d | %s | %.1f | %d | %d | %.1fs |\n" % [result["profile"], result["kit"], result["seed"], result["outcome"], result["survived_seconds"], result["level"], result["kills"], result["first_new_weapon_seconds"]]
	for flag in flags:
		markdown += "\n- " + flag + "\n"
	markdown += "\nSwarm warning counts: %s. Resisted electrical hits: %d.\n" % [JSON.stringify(response_counts), resisted]
	markdown += "\nDeterministic replay: %s. Failures: %d.\n\nFull choices, damage, mutations, health snapshots and limitations are in bot-report.json.\n" % [report["deterministic_replay"]["matches"], failures.size()]
	QAReport.text_file("res://builds/qa/BOT_REPORT.md", markdown)
	print("BOT_REPORT cases=", cases.size(), " failures=", failures.size())
	await create_timer(0.1).timeout
	quit(0 if failures.is_empty() else 1)

func compare_pickups() -> void:
	var report := QAReport.metadata("XP merge A/B / unchanged bot strategy")
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/bot-baseline-foundry-0.3.json"))
	var baseline_compatible: bool = true
	for path in baseline["combat_files_sha256"]:
		if FileAccess.get_sha256("res://" + path) != baseline["combat_files_sha256"][path]:
			baseline_compatible = false
	report["pinned_baseline_compatible"] = baseline_compatible
	report["pinned_baseline_note"] = "Numeric legacy replay checked" if baseline_compatible else "Numeric legacy replay skipped because combat/bot source changed; A/B still uses the same current combat and bot."
	var cases: Array[Dictionary] = []
	for seed_value in [101, 202]:
		for mode in ["legacy", "local"]:
			var result: Dictionary = await simulate(seed_value, "kinetic", "vanguard", MAX_SECONDS, mode)
			cases.append(result)
			if mode == "legacy" and baseline_compatible:
				for old in baseline["cases"]:
					if old["seed"] == seed_value and old["profile"] == "kinetic" and old["kit"] == "vanguard":
						for key in ["outcome", "survived_seconds", "kills", "level", "weapons_and_ranks", "xp_collected", "uncollected_xp"]:
							_check(JSON.parse_string(JSON.stringify(result[key])) == old[key], "legacy fixture did not reproduce baseline: " + key)
			print("XP_CASE seed=", seed_value, " mode=", mode, " outcome=", result["outcome"], " level=", result["level"], " xp=", result["xp_collected"], " max_merge_m=", result["max_merge_distance"])
		var collector: Dictionary = await simulate(seed_value, "kinetic", "vanguard", MAX_SECONDS, "local", "value_aware")
		cases.append(collector)
		print("XP_COLLECTOR seed=", seed_value, " outcome=", collector["outcome"], " level=", collector["level"], " xp=", collector["xp_collected"])
	report["cases"] = cases
	report["failures"] = failures
	report["limitations"] = ["Cautious rows hold the bot strategy fixed. Explicit value_aware rows change only navigation; no combat buffs.", "Two seeds diagnose this mechanism; they do not establish overall human balance."]
	QAReport.write("res://builds/qa/xp-comparison.json", report)
	var markdown := "# XP merge A/B\n\nUnchanged bot strategy and normal combat rules. Numeric legacy checks apply only when combat inputs match the pinned source.\n\n| Seed | Merge mode | Bot | Outcome | Seconds | Level | Collected XP | Left XP | Max merge distance | Peak orbs |\n|---:|---|---|---|---:|---:|---:|---:|---:|---:|\n"
	for row in cases:
		markdown += "| %d | %s | %s | %s | %.1f | %d | %d | %d | %.2fm | %d |\n" % [row["seed"], row["pickup_mode"], row["bot_policy"], row["outcome"], row["survived_seconds"], row["level"], row["xp_collected"], row["uncollected_xp"], row["max_merge_distance"], row["peak_pickups"]]
	markdown += "\nPinned baseline: %s.\n" % report["pinned_baseline_note"]
	QAReport.text_file("res://builds/qa/XP_COMPARISON.md", markdown)
	print("XP_REPORT cases=", cases.size(), " failures=", failures.size())
	await create_timer(0.1).timeout
	quit(0 if failures.is_empty() else 1)

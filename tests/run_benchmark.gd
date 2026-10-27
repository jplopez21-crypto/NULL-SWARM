extends SceneTree

const DT: float = 1.0 / 60.0
const WARMUP: int = 120
const SAMPLES: int = 600
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func scenario(count: int, quality: int) -> Dictionary:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	game.save.path = "user://qa_benchmark.json"
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.save.data = SaveStore.defaults()
	game.start_run()
	game.audio.shutdown()
	var world: CombatWorld = game.combat
	world.rng.seed = 4242
	world.director.elapsed = 600.0
	world.encounters.mini_spawned = true
	world.encounters.boss_spawned = true
	world.encounters.boss_defeated = true
	world.effects.quality = quality
	world.update_build({"orbit": 5, "thermal": 5, "arc": 5, "damage": 7})
	world.weapon.damage = 60.0
	world.weapon.interval = 0.16
	world.weapon.piercing = 3
	for i in range(count):
		var angle: float = TAU * i / count
		var radius: float = 5.0 + (i % 6) * 1.8
		var enemy := world.spawn(i % CombatWorld.DEFINITIONS.size(), Vector3(cos(angle), 0, sin(angle)) * radius)
		# Synthetic load targets stay alive so the benchmark cannot become cheaper by killing them.
		enemy.hp = 1000000000.0
		enemy.max_hp = enemy.hp
	for i in range(160):
		world.fire(Vector3.ZERO, Vector3(cos(i), 0, sin(i)))
		world.fire(Vector3(cos(i), 0, sin(i)) * 12.0, Vector3(-cos(i), 0, -sin(i)), true, 10)
	for i in range(250):
		game.pickups.drop(Vector3(cos(i * 0.7), 0, sin(i * 0.7)) * (3 + i % 20), 5)
	var samples: Array[float] = []
	var enemy_peak: int = 0
	var shot_peak: int = 0
	var effect_peak: int = 0
	var wall_start := Time.get_ticks_usec()
	for step in range(WARMUP + SAMPLES):
		# This fixture is deliberately synthetic and separate from normal-rules bot tests.
		game.player.health.invulnerable = 1.0
		var angle: float = step * DT * 0.25
		var moving := Vector2(cos(angle), sin(angle))
		var start := Time.get_ticks_usec()
		game.player.tick(DT, moving, false)
		world.tick(DT, game.player)
		game.pickups.tick(DT, game.player)
		# Sustain projectile and pickup work instead of silently draining the workload.
		for pool in [world.projectiles, world.hostile_projectiles]:
			var kept: int = 0
			for shot in pool:
				if kept >= 160:
					break
				if not shot.active:
					var a: float = kept * 0.17 + step * 0.01
					shot.activate(game.player.position + Vector3(cos(a), 0, sin(a)) * 5, Vector3(-cos(a), 0, -sin(a)), 12, 10, 30, 2)
				kept += 1
		if game.pickups.items.size() < 250:
			game.pickups.drop(game.player.position + Vector3(3, 0, 3), 5)
		if step >= WARMUP:
			samples.append(float(Time.get_ticks_usec() - start) / 1000.0)
		enemy_peak = maxi(enemy_peak, world.active_enemies)
		shot_peak = maxi(shot_peak, world.active_projectiles)
		effect_peak = maxi(effect_peak, world.effects.live.size())
		if step % 120 == 0:
			await process_frame
	var state := {"enemies": world.active_enemies, "kills": world.kills, "damage": world.damage_by_weapon.duplicate(),
		"player_x": game.player.position.x, "player_z": game.player.position.z, "xp_collected": game.pickups.total_collected,
		"shots": world.active_projectiles, "rng_state": world.rng.state}
	var total: float = 0.0
	for value in samples:
		total += value
	var result := {"requested_enemies": count, "quality": ["low", "medium", "high"][quality], "warmup_steps": WARMUP, "sample_steps": SAMPLES,
		"mean_simulation_step_ms": total / samples.size(), "p50_simulation_step_ms": QAReport.percentile(samples, 0.5),
		"p95_simulation_step_ms": QAReport.percentile(samples, 0.95), "p99_simulation_step_ms": QAReport.percentile(samples, 0.99),
		"max_simulation_step_ms": samples.max(), "enemy_peak": enemy_peak, "projectile_peak": shot_peak, "effect_peak": effect_peak,
		"memory_static_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"gameplay_fingerprint": JSON.stringify(state).sha256_text(), "wall_seconds": (Time.get_ticks_usec() - wall_start) / 1000000.0}
	if enemy_peak != count or world.kills != 0:
		failures.append("Stress fixture did not preserve requested enemies")
	game.queue_free()
	await process_frame
	return result

func run() -> void:
	var report := QAReport.metadata("synthetic combat CPU benchmark")
	report["limitations"] = ["Headless CPU simulation; excludes rendering, GPU, frame pacing and phone thermal behavior.",
		"Synthetic target invulnerability and huge enemy HP maintain load; these are NOT normal-rules playtests.",
		"Fixture sustains at least 160 friendly + 160 hostile projectiles plus game-generated shots, 250 pickups and full weapon effects.",
		"Timings include collision/AI/weapons/pickups/refill work but exclude bot decisions and render UI.",
		"No absolute FPS/performance pass threshold on shared CI hardware."]
	report["fixture_version"] = 2
	report["enemy_mix"] = "six regular archetypes including Insulator; differs from pre-0.4 fixed mix"
	var rows: Array[Dictionary] = []
	for count in [100, 300, 600]:
		var low: Dictionary = await scenario(count, 0)
		var high: Dictionary = await scenario(count, 2)
		rows.append(low)
		rows.append(high)
		if low["gameplay_fingerprint"] != high["gameplay_fingerprint"]:
			failures.append("Graphics quality changed simulation at %d enemies" % count)
		print("STRESS_CASE enemies=", count, " low_p95_ms=", low["p95_simulation_step_ms"], " high_p95_ms=", high["p95_simulation_step_ms"])
	report["scenarios"] = rows
	report["failures"] = failures
	QAReport.write("res://builds/qa/stress-report.json", report)
	var markdown := "# Synthetic combat CPU benchmark\n\nHeadless simulation timing, NOT Android FPS. Synthetic invulnerable targets maintain load.\n\n| Enemies | Quality | Peak shots | Mean ms | p95 ms | p99 ms | Peak effects |\n|---:|---|---:|---:|---:|---:|---:|\n"
	for row in rows:
		markdown += "| %d | %s | %d | %.3f | %.3f | %.3f | %d |\n" % [row["requested_enemies"], row["quality"], row["projectile_peak"], row["mean_simulation_step_ms"], row["p95_simulation_step_ms"], row["p99_simulation_step_ms"], row["effect_peak"]]
	markdown += "\nLow/high gameplay-state parity and fixed-load checks: %s. CPU: %s.\n" % ["passed" if failures.is_empty() else "FAILED", report["cpu"]]
	QAReport.text_file("res://builds/qa/STRESS_REPORT.md", markdown)
	print("STRESS_REPORT scenarios=", rows.size(), " failures=", failures.size())
	await create_timer(0.1).timeout
	quit(0 if failures.is_empty() else 1)

extends SceneTree

var failures: Array[String] = []
const QUERIES: int = 192
const LOOPS: int = 3
const ROUNDS: int = 4

func _initialize() -> void:
	call_deferred("run")

func median(values: Array[float]) -> float:
	var ordered: Array[float] = values.duplicate()
	ordered.sort()
	return (ordered[ROUNDS / 2 - 1] + ordered[ROUNDS / 2]) * 0.5

func measure(fn: Callable, points: Array[Vector3], radius: float) -> Dictionary:
	var checksum: int = 0
	var started: int = Time.get_ticks_usec()
	for repeat in range(LOOPS):
		for point in points:
			var value: Variant = fn.call(point, radius)
			checksum += value.size() if value is Array else (value.index + 1 if value != null else 0)
	return {"us_per_query": float(Time.get_ticks_usec() - started) / (QUERIES * LOOPS), "checksum": checksum}

func scenario(count: int, kind: String, radius: float) -> Dictionary:
	var grid := SpatialGrid.new()
	var legacy: SpatialGrid = preload("res://tests/legacy_spatial_grid.gd").new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 91827 + count
	var targets: Array = []
	var extent: float = 14.0 if count == 600 else 45.0
	for i in range(count):
		var target := SwarmEnemy.new()
		target.index = i
		target.active = i % 7 != 0
		target.position = Vector3(rng.randf_range(-extent, extent), 0, rng.randf_range(-extent, extent))
		targets.append(target)
	grid.rebuild(targets)
	if count > 1:
		targets[1].active = false # Stale entries must retain identical filtering.
	legacy.cells = grid.cells
	var points: Array[Vector3] = []
	for i in range(QUERIES):
		points.append(Vector3(rng.randf_range(-extent, extent), 0, rng.randf_range(-extent, extent)))
	var parity: bool = true
	for point in points:
		if grid.call(kind, point, radius) != legacy.call(kind, point, radius):
			parity = false
			failures.append("Ordered grid result differs from reference")
	var legacy_samples: Array[float] = []
	var current_samples: Array[float] = []
	var samples: Dictionary = {"legacy": legacy_samples, "current": current_samples}
	var checksums: Dictionary = {}
	for round_index in range(ROUNDS):
		checksums.clear()
		# Alternate AB/BA order on the same objects/process to reduce order bias.
		for variant in (["legacy", "current"] if round_index % 2 == 0 else ["current", "legacy"]):
			var measured: Dictionary = measure(Callable(legacy if variant == "legacy" else grid, kind), points, radius)
			samples[variant].append(measured["us_per_query"])
			checksums[variant] = measured["checksum"]
		if checksums["legacy"] != checksums["current"]:
			parity = false
			failures.append("Timed grid checksums differ")
	var legacy_median: float = median(legacy_samples)
	var current_median: float = median(current_samples)
	var row := {"allocated_targets": count, "kind": kind, "radius": radius, "queries_per_round": QUERIES * LOOPS,
		"rounds_us_per_query": samples, "legacy_median_us": legacy_median, "current_median_us": current_median,
		"speedup": legacy_median / maxf(0.00001, current_median), "checksum": checksums["current"], "ordered_parity": parity}
	grid.cells.clear()
	legacy.cells.clear()
	for target in targets:
		target.free()
	return row

func run() -> void:
	var report := QAReport.metadata("paired spatial-query kernel timing")
	var rows: Array[Dictionary] = []
	for count in [0, 100, 600]:
		for kind in ["query", "nearest"]:
			rows.append(scenario(count, kind, 2.0 if kind == "query" else 24.0))
	report["cases"] = rows
	report["failures"] = failures
	report["limitations"] = ["Same-process alternating AB/BA, four timing rounds after ordered-result warm-up.",
		"Static deterministic targets (including inactive entries), not whole combat, rendering or Android FPS.",
		"Includes Callable/checksum overhead; timings are observations without a hardware-dependent pass threshold.",
		"Allocated targets include intentionally inactive units; this is not the sustained-enemy combat fixture."]
	QAReport.write("res://builds/qa/grid-benchmark.json", report)
	for row in rows:
		print("GRID_CASE ", row["allocated_targets"], " ", row["kind"], " speedup=", snappedf(row["speedup"], 0.001), " parity=", row["ordered_parity"])
	print("GRID_BENCHMARK cases=", rows.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

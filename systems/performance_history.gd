class_name PerformanceHistory
extends RefCounted

const CAPACITY: int = 120
const INTERVAL_MS: int = 250
const FIELDS: Array[String] = ["fps", "enemies", "shots", "draws", "engine_bytes", "simulation_seconds", "quality"]
var samples: Array[Dictionary] = []
var next_ms: int = 0

func clear() -> void:
	samples.clear()
	next_ms = 0

func due(now_ms: int) -> bool:
	return now_ms >= 0 and now_ms >= next_ms

# Caller supplies actual observations only while diagnostics and combat are active.
func record(now_ms: int, values: Dictionary) -> bool:
	if not due(now_ms):
		return false
	for key in FIELDS:
		var value: Variant = values.get(key)
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0:
			return false
	if float(values["fps"]) <= 0 or float(values["quality"]) > 2 or float(values["quality"]) != float(int(values["quality"])):
		return false
	var sample: Dictionary = {"wall_ms": now_ms}
	for key in FIELDS:
		sample[key] = values[key]
	samples.append(sample)
	if samples.size() > CAPACITY:
		samples.pop_front()
	next_ms = now_ms + INTERVAL_MS
	return true

func report(context: Dictionary) -> Dictionary:
	var rates: Array[float] = []
	for sample in samples:
		rates.append(float(sample["fps"]))
	rates.sort()
	var summary: Dictionary = {"observations": rates.size()}
	if not rates.is_empty():
		var middle: int = rates.size() / 2
		summary.merge({"minimum_reported_fps": rates.front(), "maximum_reported_fps": rates.back(), "median_reported_fps": rates[middle] if rates.size() % 2 else (rates[middle - 1] + rates[middle]) * 0.5})
	var device: Dictionary = {}
	for key in ["platform", "model", "os_version", "engine", "renderer", "window", "canvas"]:
		if context.has(key):
			device[key] = context[key].duplicate(true) if context[key] is Array or context[key] is Dictionary else context[key]
	return {"schema": 1, "status": "empty" if samples.is_empty() else "observations", "device": device, "summary": summary, "samples": samples.duplicate(true),
		"scope": "Last 120 active-combat observations, at most 4 per second. Positive Godot FPS readings only; these are observations of the engine FPS window, not frame-time percentiles or CPU/GPU timings. Gaps can include pause, upgrades, disabled stats or slow frames. Quality 0/1/2 means low/medium/high. Engine bytes are Godot static allocations, not process RSS. Zero draw calls can mean an unsupported monitor. No online upload or saved progression is included."}

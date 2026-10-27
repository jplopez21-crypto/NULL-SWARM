class_name QAReport
extends RefCounted

static func metadata(kind: String) -> Dictionary:
	return {"schema": 1, "kind": kind, "godot": Engine.get_version_info()["string"], "os": OS.get_name(),
		"cpu": OS.get_processor_name(), "logical_cpus": OS.get_processor_count(), "rendering": "headless / no GPU frame measurements", "fixed_step": 1.0 / 60.0}

static func write(path: String, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write QA report: " + path)
		return
	file.store_string(JSON.stringify(data, "  "))
	file.close()

static func percentile(samples: Array[float], fraction: float) -> float:
	if samples.is_empty():
		return 0.0
	var sorted: Array[float] = samples.duplicate()
	sorted.sort()
	return sorted[clampi(ceili(sorted.size() * fraction) - 1, 0, sorted.size() - 1)]

static func text_file(path: String, contents: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(contents)
		file.close()

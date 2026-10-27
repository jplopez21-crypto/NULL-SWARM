class_name SaveStore
extends RefCounted

const VERSION: int = 1
var path: String = "user://progress.json"
var data: Dictionary = defaults()

static func defaults() -> Dictionary:
	return {"version": VERSION, "runs": 0, "kills": 0, "best_time": 0.0, "wins": 0,
		"settings": {"master": 0.8, "music": 0.35, "sfx": 0.65, "ui": 0.65, "shake": true, "flashes": true, "quality": 1}}

func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary or parsed.get("version", 0) != VERSION:
		return {}
	for key in ["runs", "kills", "best_time", "wins"]:
		if not (parsed.get(key) is float or parsed.get(key) is int) or parsed[key] < 0:
			return {}
	if not parsed.get("settings") is Dictionary:
		return {}
	var settings: Dictionary = defaults()["settings"]
	for key in settings:
		var value: Variant = parsed["settings"].get(key, settings[key])
		if key in ["shake", "flashes"]:
			if value is bool:
				settings[key] = value
		elif value is float or value is int:
			settings[key] = clampf(float(value), 0.0, 2.0 if key == "quality" else 1.0)
	parsed["settings"] = settings
	return parsed

func load_data() -> void:
	data = _read(path)
	if data.is_empty():
		data = _read(path + ".bak")
	if data.is_empty():
		data = defaults()

func persist() -> Error:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	# Preserve a verified last-good file, never rotate corrupt data into backup.
	if not _read(path).is_empty():
		var backup_error := DirAccess.copy_absolute(path, path + ".bak")
		if backup_error != OK:
			return backup_error
	return DirAccess.rename_absolute(path + ".tmp", path)

func record_run(time: float, kills: int, won: bool) -> Error:
	data["runs"] += 1
	data["kills"] += kills
	data["best_time"] = maxf(float(data["best_time"]), time)
	data["wins"] += 1 if won else 0
	return persist()

class_name SaveStore
extends RefCounted

const VERSION: int = 2
var path: String = "user://progress.json"
var data: Dictionary = defaults()
var last_error: Error = OK

static func defaults() -> Dictionary:
	return {"version": VERSION, "runs": 0, "kills": 0, "best_time": 0.0, "wins": 0,
		"salvage": 0, "salvaged_kills": 0, "wardens": 0, "architects": 0,
		"research": {}, "selected_kit": "vanguard", "ledger": {},
		"settings": {"master": 0.8, "music": 0.35, "sfx": 0.65, "ui": 0.65, "shake": true, "flashes": true, "performance_stats": false, "quality": 1}}

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= 0.0

func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return {}
	return validated(parser.data)

static func validated(source: Variant) -> Dictionary:
	if not source is Dictionary:
		return {}
	var parsed: Dictionary = source.duplicate(true)
	var version: Variant = parsed.get("version", 0)
	if not _number(version) or float(version) != int(version) or int(version) not in [1, VERSION]:
		return {}
	for key in ["runs", "kills", "best_time", "wins"]:
		if not _number(parsed.get(key)):
			return {}
	if not parsed.get("settings") is Dictionary:
		return {}
	# Version 1 -> 2 keeps statistics and settings. It grants no invented purchases.
	if int(parsed["version"]) == 1:
		var old: Dictionary = parsed
		parsed = defaults()
		for key in ["runs", "kills", "best_time", "wins", "settings"]:
			parsed[key] = old[key]
		parsed["salvaged_kills"] = old["kills"]
	for key in ["salvage", "salvaged_kills", "wardens", "architects"]:
		if not _number(parsed.get(key)):
			return {}
	if not parsed.get("research") is Dictionary or not parsed.get("ledger") is Dictionary:
		return {}
	var ranks: Dictionary = {}
	for id in Research.UPGRADES:
		var rank: Variant = parsed["research"].get(id, 0)
		if not _number(rank) or int(rank) != float(rank) or int(rank) > Research.UPGRADES[id]["costs"].size():
			return {}
		ranks[id] = int(rank)
	parsed["research"] = ranks
	var ledger: Dictionary = parsed["ledger"]
	if not ledger.is_empty():
		if not ledger.get("id") is String or not ledger.get("closed") is bool:
			return {}
		for key in ["awarded", "kills", "time"]:
			if not _number(ledger.get(key)):
				return {}
		for key in ["warden", "architect", "won"]:
			if not ledger.get(key) is bool:
				return {}
	var settings: Dictionary = defaults()["settings"]
	for key in settings:
		var value: Variant = parsed["settings"].get(key, settings[key])
		if key in ["shake", "flashes", "performance_stats"]:
			if value is bool:
				settings[key] = value
		elif _number(value):
			settings[key] = clampf(float(value), 0.0, 2.0 if key == "quality" else 1.0)
	parsed["settings"] = settings
	if not Research.unlocked(parsed).has(str(parsed.get("selected_kit", "vanguard"))):
		parsed["selected_kit"] = "vanguard"
	var clean: Dictionary = defaults()
	for key in clean:
		clean[key] = parsed.get(key, clean[key])
	return clean

# Portable offline progression only; codes are checksummed, not entitlements.
func backup_code() -> String:
	var clean := validated(data)
	if clean.is_empty():
		return ""
	clean["ledger"] = {}
	var text := JSON.stringify(clean)
	return "NS1." + Marshalls.raw_to_base64(text.to_utf8_buffer()) + "." + text.sha256_text()

static func inspect_backup(code: String) -> Dictionary:
	code = code.strip_edges()
	if code.length() > 16384:
		return {}
	var parts := code.split(".")
	if parts.size() != 3 or parts[0] != "NS1" or parts[1].length() % 4 != 0:
		return {}
	var pattern := RegEx.new()
	pattern.compile("^[A-Za-z0-9+/]+={0,2}$")
	if pattern.search(parts[1]) == null:
		return {}
	var bytes := Marshalls.base64_to_raw(parts[1])
	for byte in bytes:
		if byte < 32 or byte > 126:
			return {}
	var text := bytes.get_string_from_ascii()
	if text.sha256_text() != parts[2]:
		return {}
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var clean := validated(parser.data)
	if not clean.is_empty():
		for key in ["runs", "kills", "wins", "salvage", "salvaged_kills", "wardens", "architects"]:
			if float(clean[key]) > 2000000000.0 or float(clean[key]) != floorf(float(clean[key])):
				return {}
		clean["ledger"] = {}
	return clean

func restore_backup(code: String) -> Error:
	var imported := inspect_backup(code)
	if imported.is_empty():
		return ERR_INVALID_DATA
	# Preserve the existing progress before replacing anything, including on failure.
	var recovery := FileAccess.open(path + ".pre-import", FileAccess.WRITE)
	if recovery == null:
		return FileAccess.get_open_error()
	recovery.store_string(JSON.stringify(data))
	recovery.flush()
	recovery.close()
	if _read(path + ".pre-import").is_empty():
		return ERR_FILE_CORRUPT
	var previous := data.duplicate(true)
	data = imported
	var error := persist()
	if error != OK:
		data = previous
	return error

func load_data() -> void:
	data = _read(path)
	if data.is_empty():
		data = _read(path + ".bak")
	if data.is_empty():
		data = defaults()

func persist() -> Error:
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = FileAccess.get_open_error()
		return last_error
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if not _read(path).is_empty():
		last_error = DirAccess.copy_absolute(path, path + ".bak")
		if last_error != OK:
			return last_error
	last_error = DirAccess.rename_absolute(path + ".tmp", path)
	return last_error

func begin_run() -> String:
	var id := str(Time.get_unix_time_from_system()) + "-" + str(Time.get_ticks_usec())
	data["ledger"] = {"id": id, "closed": false, "awarded": 0, "kills": 0, "time": 0.0, "warden": false, "architect": false, "won": false}
	persist()
	return id

func checkpoint(id: String, time: float, kills: int, warden: bool = false, architect: bool = false, won: bool = false, write: bool = true) -> Error:
	var ledger: Dictionary = data["ledger"]
	if ledger.is_empty() or ledger["id"] != id or ledger["closed"] or not is_finite(time) or time < 0 or kills < 0:
		return ERR_INVALID_PARAMETER
	var fresh_kills: int = maxi(0, kills - int(ledger["kills"]))
	data["salvaged_kills"] += fresh_kills
	ledger["kills"] = maxi(kills, int(ledger["kills"]))
	ledger["time"] = maxf(time, float(ledger["time"]))
	if warden and not ledger["warden"]:
		data["wardens"] += 1
	if architect and not ledger["architect"]:
		data["architects"] += 1
	ledger["warden"] = ledger["warden"] or warden
	ledger["architect"] = ledger["architect"] or architect
	ledger["won"] = ledger["won"] or won
	var total := Research.salvage(ledger["time"], ledger["kills"], ledger["warden"], ledger["architect"], ledger["won"])
	data["salvage"] += maxi(0, total - int(ledger["awarded"]))
	ledger["awarded"] = maxi(total, int(ledger["awarded"]))
	return persist() if write else OK

func record_run(time: float, kills: int, won: bool, id: String = "", warden: bool = false, architect: bool = false) -> Error:
	var token: String = begin_run() if id.is_empty() else id
	var ledger: Dictionary = data["ledger"]
	if ledger.get("id") == token and ledger.get("closed", false):
		return OK
	var error := checkpoint(token, time, kills, warden, architect, won, false)
	if error != OK:
		return error
	data["runs"] += 1
	data["kills"] += kills
	data["best_time"] = maxf(float(data["best_time"]), time)
	data["wins"] += 1 if won else 0
	ledger["closed"] = true
	return persist()

func purchase(id: String) -> Error:
	var cost: int = Research.cost(data, id)
	if cost < 0 or int(data["salvage"]) < cost:
		return ERR_UNAVAILABLE
	var previous: int = int(data["research"].get(id, 0))
	data["salvage"] -= cost
	data["research"][id] = previous + 1
	var error := persist()
	if error != OK:
		data["salvage"] += cost
		data["research"][id] = previous
	return error

func choose_kit(id: String) -> Error:
	if not Research.unlocked(data).has(id):
		return ERR_UNAVAILABLE
	var previous: String = data["selected_kit"]
	data["selected_kit"] = id
	var error := persist()
	if error != OK:
		data["selected_kit"] = previous
	return error

extends Node

# Read-only telemetry, enabled exclusively in the opt-in debug emulator export.
var game: Node3D
var remaining: float = 0.0
var touches: int = 0
var drags: int = 0
var dashes: int = 0
var last_dash: float = 0.0
var last_player: int = 0
var rendered_state: String = ""
var rendered_panel: int = 0
var rendered_frames: int = 0

func _ready() -> void:
	RenderingServer.frame_post_draw.connect(_frame_drawn)
	print("ANDROID_QA_READY ", OS.get_user_data_dir())

func _panel_id() -> int:
	return game.ui.screen.get_instance_id() if is_instance_valid(game.ui.screen) else 0

func _frame_drawn() -> void:
	if not is_instance_valid(game):
		return
	rendered_state = ["menu", "playing", "upgrading", "paused", "results"][game.state]
	rendered_panel = _panel_id()
	rendered_frames = Engine.get_frames_drawn()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		touches += 1
	if event is InputEventScreenDrag:
		drags += 1

func _process(delta: float) -> void:
	if is_instance_valid(game.player):
		var player_id: int = game.player.get_instance_id()
		if player_id != last_player:
			last_dash = 0.0
			last_player = player_id
		if game.player.dash_cooldown > last_dash + 0.5:
			dashes += 1
		last_dash = game.player.dash_cooldown
	remaining -= delta
	if remaining <= 0.0:
		remaining = 0.2
		snapshot()

func snapshot() -> void:
	var data: Dictionary = {"schema": 1, "process": OS.get_process_id(), "sample_ticks": Time.get_ticks_msec(), "state": ["menu", "playing", "upgrading", "paused", "results"][game.state],
		"rendered_state": rendered_state, "panel": _panel_id(), "rendered_panel": rendered_panel, "rendered_frames": rendered_frames,
		"canvas": [game.ui.root.size.x, game.ui.root.size.y], "touches": touches, "drags": drags, "dashes": dashes,
		"engine": Engine.get_version_info()["string"], "renderer": RenderingServer.get_current_rendering_method(), "buttons": []}
	data["performance_stats_visible"] = game.ui.perf_label.is_visible_in_tree()
	data["performance_stats_text"] = game.ui.perf_label.text
	data["chain_feedback"] = {"visible": game.ui.surge_gauge.is_visible_in_tree(), "text": game.ui.surge_label.text, "value": game.ui.surge_gauge.value}
	data["build_text"] = game.ui.visible_build_text()
	data["memory_audio_plays"] = game.audio.memory_plays
	data["selected_kit"] = game.save.data["selected_kit"]
	data["architects"] = game.save.data["architects"]
	data["edit_fields"] = []
	for node in game.ui.root.find_children("*", "Button", true, false):
		if node.is_visible_in_tree():
			var rect: Rect2 = node.get_global_rect()
			data["buttons"].append({"text": node.text, "disabled": node.disabled, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	if is_instance_valid(game.player) and is_instance_valid(game.combat):
		data["sentry"] = {"enabled": game.combat.sentry.enabled, "remaining": game.combat.sentry.remaining,
			"activations": game.combat.sentry.activations, "shots": game.combat.sentry.shots,
			"position": [game.combat.sentry.position.x, game.combat.sentry.position.z], "status": game.ui.sentry_label.text}
		data.merge({"dash_readiness": game.ui.dash_gauge.value, "operative_visible": game.player.body.visible,
			"shield_status": game.ui.defense_label.text, "position": [game.player.position.x, game.player.position.z], "hp": game.player.health.current,
			"time": game.combat.director.elapsed, "kills": game.combat.kills, "xp": game.pickups.total_collected,
			"level": game.progress.level, "ranks": game.progress.ranks.duplicate(), "pending": game.progress.pending, "targets": []})
		for item in game.pickups.items:
			if not item["attract"]:
				data["targets"].append([item["mesh"].position.x, item["mesh"].position.z])
	data["backup_code_length"] = 0
	for field in game.ui.root.find_children("*", "TextEdit", true, false):
		if field.is_visible_in_tree():
			data["backup_code_length"] = field.text.length()
			var rect: Rect2 = field.get_global_rect()
			data["edit_fields"].append([rect.position.x, rect.position.y, rect.size.x, rect.size.y])
	data["backup_recovery_available"] = FileAccess.file_exists(game.save.path + ".pre-import")
	data["salvage"] = game.save.data["salvage"]
	data["settings"] = game.save.data["settings"].duplicate(true)
	var file := FileAccess.open("user://qa-runtime.tmp", FileAccess.WRITE)
	if file == null:
		push_error("ANDROID_QA telemetry write failed")
		return
	file.store_string(JSON.stringify(data))
	file.close()
	if DirAccess.rename_absolute("user://qa-runtime.tmp", "user://qa-runtime.json") != OK:
		push_error("ANDROID_QA telemetry rename failed")

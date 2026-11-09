extends Node

# Read-only telemetry, enabled exclusively in the opt-in debug emulator export.
var game: Node3D
var remaining: float = 0.0
var kill_stream_id: int = 0
var kill_pcm_sha256: String = ""
var touches: int = 0
var touch_releases: int = 0
var recent_touches: Array[Dictionary] = []
var drags: int = 0
var dashes: int = 0
var last_dash: float = 0.0
var last_player: int = 0
var rendered_state: String = ""
var rendered_panel: int = 0
var rendered_frames: int = 0
var foreground_generation: int = 0
var rendered_generation: int = 0
var background_events: int = 0

func _ready() -> void:
	RenderingServer.frame_post_draw.connect(_frame_drawn)
	print("ANDROID_QA_READY ", OS.get_user_data_dir())

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN]:
		foreground_generation += 1
	elif what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		background_events += 1

func _panel_id() -> int:
	return game.ui.screen.get_instance_id() if is_instance_valid(game.ui.screen) else 0

func _frame_drawn() -> void:
	if not is_instance_valid(game):
		return
	rendered_state = ["menu", "playing", "upgrading", "paused", "results"][game.state]
	rendered_panel = _panel_id()
	rendered_frames = Engine.get_frames_drawn()
	rendered_generation = foreground_generation

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touches += 1
		else:
			touch_releases += 1
		recent_touches.append({"sequence": touches + touch_releases, "index": event.index,
			"pressed": event.pressed, "canceled": event.canceled,
			"position": [event.position.x, event.position.y], "ticks": Time.get_ticks_msec()})
		if recent_touches.size() > 8:
			recent_touches.pop_front()
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
	data["lifecycle"] = {"foreground_generation": foreground_generation, "rendered_generation": rendered_generation, "background_events": background_events}
	data["input_delivery"] = {"presses": touches, "releases": touch_releases,
		"recent": recent_touches.duplicate(true), "window_focused": get_window().has_focus()}
	data["performance_stats_visible"] = game.ui.perf_label.is_visible_in_tree()
	data["performance_stats_text"] = game.ui.perf_label.text
	data["chain_feedback"] = {"visible": game.ui.surge_gauge.is_visible_in_tree(), "text": game.ui.surge_label.text, "value": game.ui.surge_gauge.value}
	data["build_text"] = game.ui.visible_build_text()
	data["run_analysis_text"] = game.ui.visible_run_analysis()
	data["results_title"] = game.ui.results_heading.text if is_instance_valid(game.ui.results_heading) and game.ui.results_heading.is_visible_in_tree() else ""
	data["memory_audio_plays"] = game.audio.memory_plays
	data["touch_controls"] = {"joystick_id": game.input_router.touch_id,
		"stick": [game.input_router.stick.x, game.input_router.stick.y],
		"dash_id": game.ui.dash_button.touch_id, "dash_enabled": game.ui.dash_button.input_enabled,
		"pause_id": game.ui.pause_button.touch_id, "pause_enabled": game.ui.pause_button.input_enabled}
	data["performance_report_text"] = game.ui.visible_performance_report()
	data["performance_copy_status"] = game.ui.performance_copy_status.text if is_instance_valid(game.ui.performance_copy_status) and game.ui.performance_copy_status.is_visible_in_tree() else ""
	data["selected_kit"] = game.save.data["selected_kit"]
	data["architects"] = game.save.data["architects"]
	data["edit_fields"] = []
	for node in game.ui.root.find_children("*", "Button", true, false):
		if node.is_visible_in_tree():
			var rect: Rect2 = node.get_global_rect()
			data["buttons"].append({"text": node.text, "disabled": node.disabled, "rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]})
	if is_instance_valid(game.player) and is_instance_valid(game.combat):
		data["attack_lanes"] = _lane_geometry()
		var model := {"instances": 0, "surfaces": 0, "triangles": 0}
		for node in game.player.body.get_children():
			if node is MeshInstance3D:
				model["instances"] += 1
				model["surfaces"] += node.mesh.get_surface_count()
				for surface in range(node.mesh.get_surface_count()):
					model["triangles"] += node.mesh.surface_get_array_len(surface) / 3
		data["operative_visuals"] = model
		var fragments: int = 0
		for item in game.combat.effects.live:
			if item["kind"] == "shard" and item["mesh"].mesh == game.combat.effects.shard_mesh:
				fragments += 1
		var cue: AudioStreamWAV = game.audio.sounds.get("kill")
		if cue == null:
			kill_stream_id = 0
			kill_pcm_sha256 = ""
		elif cue.get_instance_id() != kill_stream_id:
			kill_stream_id = cue.get_instance_id()
			var digest := HashingContext.new()
			digest.start(HashingContext.HASH_SHA256)
			digest.update(cue.data)
			kill_pcm_sha256 = digest.finish().hex_encode()
		data["destruction_feedback"] = {"fragments_live": fragments,
			"fragment_triangles": game.combat.effects.shard_mesh.surface_get_array_len(0) / 3,
			"kill_cue_last_dispatch_ms": game.audio.last_dispatched.get("kill", -1),
			"kill_cue_pcm_bytes": cue.data.size() if cue != null else 0, "kill_cue_pcm_sha256": kill_pcm_sha256}
		data["sentry"] = {"enabled": game.combat.sentry.enabled, "remaining": game.combat.sentry.remaining,
			"activations": game.combat.sentry.activations, "shots": game.combat.sentry.shots,
			"position": [game.combat.sentry.position.x, game.combat.sentry.position.z], "status": game.ui.sentry_label.text}
		data.merge({"dash_readiness": game.ui.dash_gauge.value, "operative_visible": game.player.body.visible,
			"shield_status": game.ui.defense_label.text, "position": [game.player.position.x, game.player.position.z], "hp": game.player.health.current,
			"time": game.combat.director.elapsed, "kills": game.combat.kills, "xp": game.pickups.total_collected,
			"damage_by_weapon": game.combat.damage_by_weapon.duplicate(), "combat_rng": str(game.combat.rng.state), "level": game.progress.level, "ranks": game.progress.ranks.duplicate(), "pending": game.progress.pending, "targets": []})
		data["health"] = {"current": game.player.health.current, "maximum": game.player.health.maximum,
			"shield": game.player.health.shield, "max_shield": game.player.health.max_shield}
		data["corruption"] = {"accepted": game.combat.corruption.accepted.duplicate(), "next_level": game.combat.corruption.next_level,
			"cycle_rate": game.combat.corruption.cycle_rate(), "enemy_pace": game.combat.corruption.enemy_pace(),
			"walk_rate": game.combat.corruption.walk_rate(), "extra_rounds": game.combat.corruption.extra_rounds(), "extra_drones": game.combat.corruption.extra_drones()}
		for item in game.pickups.items:
			if not item["attract"]:
				data["targets"].append([item["mesh"].position.x, item["mesh"].position.z])
	data["backup_code_length"] = 0
	for field in game.ui.root.find_children("*", "TextEdit", true, false):
		if field.is_visible_in_tree() and field.editable:
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

func _lane_geometry() -> Dictionary:
	# Read actual pooled meshes, including inactive slots; not an observed attack.
	var result: Dictionary = {}
	for enemy in game.combat.enemies:
		if enemy.definition.behavior not in [1, 2]:
			continue
		var id: String = "charge" if enemy.definition.behavior == 1 else "sentry"
		if result.has(id):
			continue
		var mesh: Mesh = enemy.telegraph.mesh
		result[id] = {"triangles": mesh.surface_get_array_len(0) / 3, "surfaces": mesh.get_surface_count(),
			"length": mesh.get_aabb().size.z, "width": mesh.get_aabb().size.x,
			"ground_mesh": enemy.telegraph.name == "AttackLane" and enemy.telegraph.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF}
		if result.size() == 2:
			break
	return result

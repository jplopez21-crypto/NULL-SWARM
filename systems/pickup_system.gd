class_name PickupSystem
extends Node3D

const CRYSTALS = preload("res://effects/memory_crystals.gd")
const SOFT_BUDGET: int = 300
const MERGE_RADIUS: float = 3.0
var items: Array[Dictionary] = []
var pooled: Array[MeshInstance3D] = []
var total_collected: int = 0
var total_dropped: int = 0
var merged_count: int = 0
var max_merge_distance: float = 0.0
var peak_count: int = 0

func drop(at: Vector3, amount: int) -> void:
	if amount <= 0:
		return
	total_dropped += amount
	if items.size() >= SOFT_BUDGET:
		var nearest: Dictionary = {}
		var distance: float = MERGE_RADIUS * MERGE_RADIUS
		for item in items:
			# Never move fresh XP into an orb already travelling toward the player.
			if item["attract"]:
				continue
			var offset: Vector3 = item["mesh"].position - at
			offset.y = 0.0
			var squared := offset.length_squared()
			if squared <= distance:
				nearest = item
				distance = squared
		if not nearest.is_empty():
			nearest["xp"] += amount
			merged_count += 1
			max_merge_distance = maxf(max_merge_distance, sqrt(distance))
			_present(nearest["mesh"], nearest["xp"])
			return
	# Soft budget: retain a separate pickup when no fair local merge exists.
	# Existing XP never changes location; fresh XP moves at most MERGE_RADIUS.
	var mesh: MeshInstance3D
	if pooled.is_empty():
		mesh = MeshInstance3D.new()
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
	else:
		mesh = pooled.pop_back()
	mesh.position = at + Vector3(0, 0.35, 0)
	mesh.visible = true
	_present(mesh, amount)
	items.append({"mesh": mesh, "xp": amount, "attract": false})
	peak_count = maxi(peak_count, items.size())

func _present(mesh: MeshInstance3D, xp: int) -> void:
	mesh.scale = Vector3.ONE * clampf(1.0 + log(maxf(1.0, float(xp) / 5.0)) * 0.22, 1.0, 2.5)
	mesh.mesh = CRYSTALS.mesh(xp)
	mesh.material_override = CRYSTALS.material(xp)

func tick(delta: float, player: SwarmPlayer) -> int:
	var earned: int = 0
	for i in range(items.size() - 1, -1, -1):
		var item: Dictionary = items[i]
		var mesh: MeshInstance3D = item["mesh"]
		var target := player.position + Vector3(0, 0.35, 0)
		var distance_before_moving := mesh.position.distance_squared_to(target)
		if distance_before_moving < player.magnet * player.magnet:
			item["attract"] = true
		if item["attract"]:
			mesh.position = mesh.position.move_toward(target, delta * 15.0)
		if distance_before_moving < 0.7:
			earned += int(item["xp"])
			mesh.visible = false
			pooled.append(mesh)
			items.remove_at(i)
	total_collected += earned
	return earned

func outstanding_xp() -> int:
	var amount: int = 0
	for item in items:
		amount += int(item["xp"])
	return amount

func vacuum() -> void:
	for item in items:
		item["attract"] = true

# Read-only locator. Never attracts, moves or grants a packet.
func memory_target(at: Vector3, attraction_radius: float, preferred: MeshInstance3D = null) -> MeshInstance3D:
	var nearest: MeshInstance3D
	var nearest_distance: float = INF
	var preferred_distance: float = INF
	for item in items:
		if item["attract"]:
			continue
		var mesh: MeshInstance3D = item["mesh"]
		var offset := mesh.position - at
		offset.y = 0.0
		var distance := offset.length_squared()
		if distance <= attraction_radius * attraction_radius:
			continue
		if distance < nearest_distance:
			nearest = mesh
			nearest_distance = distance
		if is_instance_valid(preferred) and mesh == preferred:
			preferred_distance = distance
	# Stay with the current packet unless another is meaningfully closer.
	if preferred_distance < INF and preferred_distance <= nearest_distance * 1.44:
		return preferred
	return nearest

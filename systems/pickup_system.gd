class_name PickupSystem
extends Node3D

var items: Array[Dictionary] = []
var pooled: Array[MeshInstance3D] = []
var total_collected: int = 0

func drop(at: Vector3, amount: int) -> void:
	var mesh: MeshInstance3D
	if pooled.is_empty():
		mesh = SwarmVisuals.sphere(self, 0.16, Vector3.ZERO, Color("58d5ff"))
	else:
		mesh = pooled.pop_back()
	mesh.position = at + Vector3(0, 0.35, 0)
	mesh.visible = true
	items.append({"mesh": mesh, "xp": amount, "attract": false})
	# Coalesce distant pickups without dropping any earned experience.
	if items.size() > 300:
		var first: Dictionary = items.pop_front()
		items[0]["xp"] += first["xp"]
		first["mesh"].visible = false
		pooled.append(first["mesh"])

func tick(delta: float, player: SwarmPlayer) -> int:
	var earned: int = 0
	for i in range(items.size() - 1, -1, -1):
		var item: Dictionary = items[i]
		var mesh: MeshInstance3D = item["mesh"]
		var offset := player.position + Vector3(0, 0.35, 0) - mesh.position
		if offset.length_squared() < player.magnet * player.magnet:
			item["attract"] = true
		if item["attract"]:
			mesh.position = mesh.position.move_toward(player.position + Vector3(0, 0.35, 0), delta * 15.0)
		if offset.length_squared() < 0.7:
			earned += int(item["xp"])
			mesh.visible = false
			pooled.append(mesh)
			items.remove_at(i)
	total_collected += earned
	return earned

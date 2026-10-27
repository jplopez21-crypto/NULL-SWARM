class_name CombatEffects
extends Node3D

var pool: Array[MeshInstance3D] = []
var live: Array[Dictionary] = []
var quality: int = 1
var flashes: bool = true
var ring_mesh: TorusMesh
var beam_mesh: BoxMesh

func _ready() -> void:
	ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 0.90
	ring_mesh.outer_radius = 1.0
	ring_mesh.rings = 24
	ring_mesh.ring_segments = 6
	beam_mesh = BoxMesh.new()
	beam_mesh.size = Vector3.ONE
	for i in range(160):
		var mesh := MeshInstance3D.new()
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mesh)
		mesh.visible = false
		pool.append(mesh)

func emit_fx(kind: String, at: Vector3, to: Vector3, color: Color, size: float = 1.0) -> void:
	var limit: int = [40, 85, 150][quality]
	if live.size() >= limit or pool.is_empty() or (not flashes and kind == "spark"):
		return
	var mesh: MeshInstance3D = pool.pop_back()
	mesh.mesh = beam_mesh if kind in ["beam", "spark"] else ring_mesh
	mesh.material_override = SwarmVisuals.material(color, true)
	mesh.rotation = Vector3.ZERO
	mesh.position = at + Vector3(0, 0.12, 0)
	if kind == "beam":
		mesh.position = (at + to) * 0.5 + Vector3(0, 0.8, 0)
		if at.distance_to(to) > 0.01:
			mesh.look_at(to + Vector3(0, 0.8, 0))
		mesh.scale = Vector3(size, size, maxf(0.1, at.distance_to(to)))
	elif kind == "spark":
		mesh.position.y = 0.8
		mesh.scale = Vector3(size, size * 0.3, size)
		mesh.rotation.y = randf() * TAU
	else:
		mesh.scale = Vector3(size * 0.4, 0.4, size * 0.4)
	mesh.visible = true
	live.append({"mesh": mesh, "life": 0.0, "duration": 0.12 if kind == "beam" else 0.38, "size": size, "kind": kind})

func tick(delta: float) -> void:
	for i in range(live.size() - 1, -1, -1):
		var fx: Dictionary = live[i]
		fx["life"] += delta
		var mesh: MeshInstance3D = fx["mesh"]
		var fraction: float = fx["life"] / fx["duration"]
		if fraction >= 1.0:
			mesh.visible = false
			pool.append(mesh)
			live.remove_at(i)
		elif fx["kind"] not in ["beam", "spark"]:
			var radius: float = fx["size"] * lerpf(0.4, 1.0, fraction)
			mesh.scale = Vector3(radius, (1.0 - fraction) * 0.4, radius)
		elif fx["kind"] == "spark":
			mesh.scale *= 1.0 - delta * 5.0

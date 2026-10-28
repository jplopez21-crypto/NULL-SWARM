class_name CombatEffects
extends Node3D

const DURATIONS: Dictionary = {"beam": 0.12, "dash": 0.16, "spark": 0.18, "shard": 0.65, "uplink": 0.65}

var pool: Array[MeshInstance3D] = []
var live: Array[Dictionary] = []
var quality: int = 1
var flashes: bool = true
var ring_mesh: TorusMesh
var impact_materials: Dictionary = {}
var impact_mesh: ArrayMesh
var beam_mesh: BoxMesh

func _ready() -> void:
	# A shared four-point impact silhouette: one mesh, no lights or particles.
	var vertices := PackedVector3Array()
	for i in range(8):
		var a := float(i) * TAU / 8.0
		var b := float(i + 1) * TAU / 8.0
		var r1 := 1.0 if i % 2 == 0 else 0.22
		var r2 := 1.0 if (i + 1) % 2 == 0 else 0.22
		vertices.append(Vector3.ZERO)
		vertices.append(Vector3(cos(b), 0, sin(b)) * r2)
		vertices.append(Vector3(cos(a), 0, sin(a)) * r1)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	impact_mesh = ArrayMesh.new()
	impact_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
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
	if live.size() >= limit or pool.is_empty() or (not flashes and kind in ["spark", "dash"]):
		return
	var mesh: MeshInstance3D = pool.pop_back()
	mesh.mesh = impact_mesh if kind == "spark" else (beam_mesh if kind in ["beam", "dash", "shard"] else ring_mesh)
	if kind == "spark":
		if not impact_materials.has(color):
			var material: StandardMaterial3D = SwarmVisuals.material(color, true).duplicate()
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			impact_materials[color] = material
		mesh.material_override = impact_materials[color]
	else:
		mesh.material_override = SwarmVisuals.material(color, true)
	mesh.rotation = Vector3.ZERO
	mesh.position = at + Vector3(0, 0.12, 0)
	if kind in ["beam", "dash"]:
		var height: float = 0.3 if kind == "dash" else 0.8
		mesh.position = (at + to) * 0.5 + Vector3(0, height, 0)
		if at.distance_to(to) > 0.01:
			mesh.look_at(to + Vector3(0, height, 0))
		mesh.scale = Vector3(size, size, maxf(0.1, at.distance_to(to)))
	elif kind in ["spark", "shard"]:
		mesh.position.y = at.y + 0.8
		mesh.scale = Vector3(size, size * 0.3, size * (2.4 if kind == "shard" else 1.0))
		mesh.rotation.y = randf() * TAU
	else:
		mesh.scale = Vector3(size * 0.4, 0.4, size * 0.4)
	mesh.visible = true
	live.append({"mesh": mesh, "life": 0.0, "duration": float(DURATIONS.get(kind, 0.38)), "size": size, "kind": kind, "velocity": Vector3(randf_range(-4.0, 4.0), randf_range(2.0, 5.0), randf_range(-4.0, 4.0))})

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
		elif fx["kind"] not in ["beam", "dash", "spark", "shard"]:
			var radius: float = fx["size"] * lerpf(0.4, 1.0, 1.0 - pow(1.0 - fraction, 2.0))
			if fx["kind"] == "uplink":
				mesh.position.y += delta * 2.2
			mesh.scale = Vector3(radius, (1.0 - fraction) * 0.4, radius)
		elif fx["kind"] == "shard":
			fx["velocity"].y -= delta * 12.0
			mesh.position += fx["velocity"] * delta
			mesh.rotate_x(delta * 7.0)
			mesh.rotate_z(delta * 4.0)
			mesh.scale *= maxf(0.0, 1.0 - delta * 1.7)
		elif fx["kind"] == "dash":
			mesh.scale.x = fx["size"] * (1.0 - fraction)
			mesh.scale.y = mesh.scale.x
		elif fx["kind"] == "spark":
			mesh.scale = Vector3.ONE * fx["size"] * (1.0 - fraction)

func destruction(at: Vector3, color: Color, large: bool) -> void:
	emit_fx("ring", at, at, color, 5.0 if large else 1.2)
	if not flashes:
		return
	var count: int = [2, 4, 6][quality] * (2 if large else 1)
	for i in range(count):
		emit_fx("shard", at, at, color.lightened(0.2), 0.45 if large else 0.22)

class_name SwarmVisuals
extends RefCounted

static var materials: Dictionary = {}

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key := str(color) + str(glow)
	if not materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.85
		if glow:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		materials[key] = mat
	return materials[key]

static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color, glow)
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

static func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 8
	shape.rings = 4
	mesh.mesh = shape
	mesh.material_override = material(color, true)
	mesh.position = pos
	parent.add_child(mesh)
	return mesh

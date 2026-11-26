extends RefCounted

# Original shared development armor. No textures, skeleton, lights or frame work.
static var meshes: Dictionary = {}
static var materials: Dictionary = {}
const ARMOR := Color("31576a")
const PLATE := Color("6c9aab")
const DARK := Color("172d3c")
const ENERGY := Color("80ffdb")

static func material(glow: bool) -> StandardMaterial3D:
	if not materials.has(glow):
		var result := StandardMaterial3D.new()
		result.vertex_color_use_as_albedo = true
		result.vertex_color_is_srgb = true
		result.roughness = 0.8
		result.metallic = 0.18
		if glow:
			result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		materials[glow] = result
	return materials[glow]

static func build(parent: Node3D) -> Dictionary:
	instance(parent, "armor", "OperativeArmor", Vector3.ZERO)
	instance(parent, "visor", "OperativeVisor", Vector3.ZERO)
	var legs: Array[MeshInstance3D] = []
	for side in [-1.0, 1.0]:
		legs.append(instance(parent, "leg", "OperativeLeg", Vector3(side * 0.25, 0.28, 0)))
	var gun := instance(parent, "rifle", "OperativeRifle", Vector3(0.5, 1.0, -0.5))
	return {"legs": legs, "gun": gun}

static func instance(parent: Node3D, id: String, title: String, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = title
	node.mesh = mesh(id)
	node.position = at
	parent.add_child(node)
	return node

static func mesh(id: String) -> ArrayMesh:
	if meshes.has(id):
		return meshes[id]
	var result := ArrayMesh.new()
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match id:
		"armor":
			prism(tool, bevel(Vector2.ZERO, Vector2(0.39, 0.32), 0.10), 0.70, 1.36, 0.84, ARMOR)
			prism(tool, hexagon(Vector2.ZERO, Vector2(0.32, 0.27)), 0.48, 0.75, 0.91, DARK)
			for side in [-1.0, 1.0]:
				prism(tool, hexagon(Vector2(side * 0.51, 0), Vector2(0.23, 0.29)), 1.02, 1.34, 0.78, PLATE)
			prism(tool, bevel(Vector2(0, -0.03), Vector2(0.33, 0.31), 0.10), 1.40, 1.82, 0.86, Color("8abfc8"))
			prism(tool, rectangle(Vector2(0, 0.37), Vector2(0.38, 0.24)), 0.87, 1.33, 0.86, PLATE)
		"visor":
			# Front visor and crown stripe remain visible from the elevated camera.
			quad(tool, Vector3(-0.245, 1.56, -0.345), Vector3(0.245, 1.56, -0.345),
				Vector3(0.245, 1.67, -0.345), Vector3(-0.245, 1.67, -0.345), ENERGY)
			quad(tool, Vector3(-0.055, 1.825, -0.19), Vector3(0.055, 1.825, -0.19),
				Vector3(0.055, 1.825, 0.15), Vector3(-0.055, 1.825, 0.15), Color("e5fff5"))
		"leg":
			prism(tool, hexagon(Vector2(0, 0.015), Vector2(0.13, 0.13)), -0.16, 0.25, 0.80, ARMOR)
			prism(tool, hexagon(Vector2(0, -0.04), Vector2(0.15, 0.22)), -0.25, -0.10, 0.86, PLATE)
		"rifle":
			prism(tool, hexagon(Vector2(0, 0.08), Vector2(0.14, 0.32)), -0.11, 0.10, 0.88, DARK)
			prism(tool, rectangle(Vector2(0, -0.31), Vector2(0.16, 0.40)), -0.055, 0.045, 0.92, PLATE)
		_:
			push_error("Unknown operative mesh: " + id)
			return result
	tool.commit(result)
	result.surface_set_material(0, material(id == "visor"))
	if id == "rifle":
		tool = SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		quad(tool, Vector3(-0.055, 0.105, -0.12), Vector3(0.055, 0.105, -0.12),
			Vector3(0.055, 0.105, 0.30), Vector3(-0.055, 0.105, 0.30), ENERGY)
		quad(tool, Vector3(-0.07, -0.04, -0.515), Vector3(0.07, -0.04, -0.515),
			Vector3(0.07, 0.04, -0.515), Vector3(-0.07, 0.04, -0.515), Color("e5fff5"))
		tool.commit(result)
		result.surface_set_material(1, material(true))
	meshes[id] = result
	return result

static func rectangle(center: Vector2, size: Vector2) -> Array[Vector2]:
	return [center + Vector2(-size.x, -size.y) * 0.5, center + Vector2(size.x, -size.y) * 0.5,
		center + size * 0.5, center + Vector2(-size.x, size.y) * 0.5]

static func hexagon(center: Vector2, radius: Vector2) -> Array[Vector2]:
	return [center + Vector2(-radius.x * 0.65, -radius.y), center + Vector2(radius.x * 0.65, -radius.y),
		center + Vector2(radius.x, 0), center + radius, center + Vector2(-radius.x, radius.y),
		center + Vector2(-radius.x, 0)]

static func bevel(center: Vector2, radius: Vector2, cut: float) -> Array[Vector2]:
	return [center + Vector2(-radius.x + cut, -radius.y), center + Vector2(radius.x - cut, -radius.y),
		center + Vector2(radius.x, -radius.y + cut), center + Vector2(radius.x, radius.y - cut),
		center + Vector2(radius.x - cut, radius.y), center + Vector2(-radius.x + cut, radius.y),
		center + Vector2(-radius.x, radius.y - cut), center + Vector2(-radius.x, -radius.y + cut)]

static func prism(tool: SurfaceTool, points: Array[Vector2], bottom: float, top: float, inset: float, color: Color) -> void:
	var center := Vector2.ZERO
	for p in points:
		center += p
	center /= points.size()
	for i in range(points.size()):
		var p: Vector2 = points[i]
		var q: Vector2 = points[(i + 1) % points.size()]
		var a: Vector2 = center + (p - center) * inset
		var b: Vector2 = center + (q - center) * inset
		quad(tool, Vector3(p.x, bottom, p.y), Vector3(q.x, bottom, q.y), Vector3(b.x, top, b.y), Vector3(a.x, top, a.y), color.darkened(0.18))
		triangle(tool, Vector3(center.x, top, center.y), Vector3(a.x, top, a.y), Vector3(b.x, top, b.y), color)
		triangle(tool, Vector3(center.x, bottom, center.y), Vector3(q.x, bottom, q.y), Vector3(p.x, bottom, p.y), color.darkened(0.35))

static func quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	triangle(tool, a, b, c, color)
	triangle(tool, a, c, d, color)

static func triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	tool.set_normal((c - a).cross(b - a).normalized())
	tool.set_color(color)
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)

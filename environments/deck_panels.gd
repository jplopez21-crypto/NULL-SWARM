extends RefCounted

# Original static deck artwork: two cached single-surface meshes, no textures.
static var meshes: Dictionary = {}
static var shared_material: StandardMaterial3D

static func material() -> StandardMaterial3D:
	if shared_material == null:
		shared_material = StandardMaterial3D.new()
		shared_material.vertex_color_use_as_albedo = true
		shared_material.vertex_color_is_srgb = true
		shared_material.roughness = 0.96
		shared_material.metallic = 0.15
	return shared_material

static func mesh(variant: int) -> ArrayMesh:
	var key: int = clampi(variant, 0, 1)
	if meshes.has(key):
		return meshes[key]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var outer: Array[Vector3] = outline(2.45, 0.28, 0.012)
	var inner: Array[Vector3] = outline(2.31, 0.22, 0.035)
	for i in range(8):
		var next: int = (i + 1) % 8
		quad(tool, outer[i], outer[next], inner[next], inner[i], Color("1c2d37"))
		triangle(tool, Vector3(0, 0.035, 0), inner[i], inner[next], Color("12212a"))
	if key == 1:
		# Recessed service hatches appear on just one panel in four in the arena.
		rect(tool, Vector2(-1.3, -0.9), Vector2(2.6, 1.8), 0.037, Color("0d1820"))
		rect(tool, Vector2(-1.18, -0.78), Vector2(2.36, 1.56), 0.039, Color("182832"))
		for i in range(3):
			rect(tool, Vector2(-0.9, -0.48 + i * 0.35), Vector2(1.8, 0.12), 0.041, Color("0b161d"))
	# Fastener marks stay broad enough to avoid a field of subpixel highlights.
	for x in [-1.9, 1.9]:
		for z in [-1.9, 1.9]:
			if key == 0 and x != z:
				continue
			rect(tool, Vector2(x - 0.06, z - 0.06), Vector2(0.12, 0.12), 0.037, Color("394650"))
	for i in range(2 if key == 0 else 3):
		rect(tool, Vector2(-1.7 + i * 0.2, -2.0), Vector2(0.09, 0.22 + i * 0.06), 0.037, Color("48514f"))
	if key == 1:
		# A second service layout breaks up repetition without a checkerboard tint.
		rect(tool, Vector2(1.65, -1.55), Vector2(0.32, 3.1), 0.037, Color("0b171e"))
		rect(tool, Vector2(1.76, -1.2), Vector2(0.1, 0.5), 0.039, Color("2e6669"))
		for i in range(2):
			var x: float = -1.94 + i * 0.26
			quad(tool, Vector3(x, 0.037, 1.38), Vector3(x + 0.12, 0.037, 1.38), Vector3(x + 0.38, 0.037, 1.8), Vector3(x + 0.26, 0.037, 1.8), Color("706144"))
	var result: ArrayMesh = tool.commit()
	meshes[key] = result
	return result

static func outline(radius: float, cut: float, height: float) -> Array[Vector3]:
	return [Vector3(-radius + cut, height, -radius), Vector3(radius - cut, height, -radius),
		Vector3(radius, height, -radius + cut), Vector3(radius, height, radius - cut),
		Vector3(radius - cut, height, radius), Vector3(-radius + cut, height, radius),
		Vector3(-radius, height, radius - cut), Vector3(-radius, height, -radius + cut)]

static func rect(tool: SurfaceTool, corner: Vector2, size: Vector2, height: float, color: Color) -> void:
	quad(tool, Vector3(corner.x, height, corner.y), Vector3(corner.x + size.x, height, corner.y),
		Vector3(corner.x + size.x, height, corner.y + size.y), Vector3(corner.x, height, corner.y + size.y), color)

static func quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	triangle(tool, a, b, c, color)
	triangle(tool, a, c, d, color)

static func triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	# Godot front faces use clockwise winding. These normals face the lit deck top.
	var normal: Vector3 = (c - a).cross(b - a).normalized()
	tool.set_color(color)
	tool.set_normal(normal)
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)

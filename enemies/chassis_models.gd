extends RefCounted

# Original, bounded procedural hulls for the six canonical regular archetypes.
const IDS: Array[StringName] = [&"crawler", &"striker", &"sentry", &"bulwark", &"skimmer", &"insulator"]
static var meshes: Dictionary = {}
static var materials: Dictionary = {}

static func supports(id: StringName) -> bool:
	return IDS.has(id)

static func material(id: StringName, color: Color) -> StandardMaterial3D:
	var key: StringName = id if supports(id) else &"crawler"
	if not materials.has(key):
		var result := StandardMaterial3D.new()
		result.vertex_color_use_as_albedo = true
		result.vertex_color_is_srgb = true
		result.roughness = 0.8
		result.metallic = 0.18
		materials[key] = result
	# Canonical IDs share their definition's tint, independent of hull geometry.
	materials[key].albedo_color = color
	return materials[key]

static func mesh(id: StringName) -> ArrayMesh:
	var key: StringName = id if supports(id) else &"crawler"
	if meshes.has(key):
		return meshes[key]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	match key:
		&"crawler":
			prism(tool, octagon(0.43, 0.48, 0.15), 0.28, 0.8, 0.88, 0.1, 0.86)
			for side in [-1.0, 1.0]:
				prism(tool, rectangle(Vector2(side * 0.52, 0.03), Vector2(0.22, 1.1)), 0.16, 0.39, 0.92, 0, 0.52)
				prism(tool, [Vector2(side * 0.35 - 0.1, -0.35), Vector2(side * 0.35, -0.72), Vector2(side * 0.35 + 0.1, -0.35)], 0.24, 0.44, 1, 0.04, 1)
		&"striker":
			prism(tool, [Vector2(-0.54, 0.4), Vector2(0, -0.7), Vector2(0.54, 0.4)], 0.22, 0.88, 0.75, 0.3, 1)
			for side in [-1.0, 1.0]:
				var wing: Array[Vector2] = [Vector2(side * 0.35 - 0.13, 0.2), Vector2(side * 0.35, -0.02), Vector2(side * 0.35 + 0.13, 0.2)]
				prism(tool, wing, 0.24, 0.45, 1, 0.05, 0.65)
		&"sentry":
			prism(tool, polygon(6, Vector2(0.65, 0.58)), 0.16, 0.4, 0.86, 0, 0.52)
			prism(tool, octagon(0.29, 0.3, 0.1), 0.4, 1.18, 0.9, 0.08, 0.88)
			prism(tool, rectangle(Vector2(0, -0.42), Vector2(0.3, 0.6)), 0.88, 1.08, 0.9, 0, 1)
			for side in [-1.0, 1.0]:
				prism(tool, rectangle(Vector2(side * 0.43, 0.12), Vector2(0.12, 0.16)), 0.76, 1.5, 0.75, 0.04, 0.72)
		&"bulwark":
			prism(tool, octagon(0.64, 0.48, 0.16), 0.14, 1.16, 0.88, 0.12, 0.58)
			for side in [-1.0, 1.0]:
				prism(tool, rectangle(Vector2(side * 0.7, 0.02), Vector2(0.24, 1.0)), 0.24, 1.3, 0.88, 0, 0.78)
			var shield: Array[Vector2] = octagon(0.8, 0.13, 0.07)
			for i in range(shield.size()):
				shield[i].y -= 0.59
			prism(tool, shield, 0.28, 1.08, 0.95, 0.07, 1)
			quad(tool, Vector3(-0.55, 0.78, -0.725), Vector3(0.55, 0.78, -0.725), Vector3(0.55, 0.92, -0.725), Vector3(-0.55, 0.92, -0.725), 0.35)
		&"skimmer":
			prism(tool, [Vector2(-0.84, 0.18), Vector2(-0.4, -0.18), Vector2(0, -0.62), Vector2(0.4, -0.18), Vector2(0.84, 0.18), Vector2(0, 0.4)], 0.97, 1.1, 0.95, 0.08, 1)
			prism(tool, octagon(0.3, 0.33, 0.1), 0.85, 1.36, 0.7, 0.1, 0.6)
			for side in [-1.0, 1.0]:
				prism(tool, rectangle(Vector2(side * 0.64, 0.25), Vector2(0.22, 0.3)), 0.83, 1.08, 0.8, 0, 0.68)
		&"insulator":
			prism(tool, octagon(0.34, 0.4, 0.12), 0.2, 1.0, 0.85, 0.12, 0.6)
			for side in [-1.0, 1.0]:
				prism(tool, rectangle(Vector2(side * 0.56, 0.02), Vector2(0.16, 0.2)), 0.32, 1.42, 0.85, 0.04, 1)
			coil(tool)
	var result: ArrayMesh = tool.commit()
	meshes[key] = result
	return result

static func rectangle(center: Vector2, size: Vector2) -> Array[Vector2]:
	return [center + Vector2(-size.x, -size.y) * 0.5, center + Vector2(size.x, -size.y) * 0.5,
		center + size * 0.5, center + Vector2(-size.x, size.y) * 0.5]

static func octagon(x: float, z: float, cut: float) -> Array[Vector2]:
	return [Vector2(-x + cut, -z), Vector2(x - cut, -z), Vector2(x, -z + cut), Vector2(x, z - cut),
		Vector2(x - cut, z), Vector2(-x + cut, z), Vector2(-x, z - cut), Vector2(-x, -z + cut)]

static func polygon(count: int, radius: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for i in range(count):
		var angle: float = -PI * 0.5 + TAU * i / count
		result.append(Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return result

static func prism(tool: SurfaceTool, points: Array[Vector2], bottom: float, top: float, inset: float, peak: float, shade: float) -> void:
	var center := Vector2.ZERO
	for p in points:
		center += p
	center /= points.size()
	for i in range(points.size()):
		var p: Vector2 = points[i]
		var q: Vector2 = points[(i + 1) % points.size()]
		var a: Vector2 = center + (p - center) * inset
		var b: Vector2 = center + (q - center) * inset
		quad(tool, Vector3(p.x, bottom, p.y), Vector3(q.x, bottom, q.y), Vector3(b.x, top, b.y), Vector3(a.x, top, a.y), shade * 0.65)
		triangle(tool, Vector3(center.x, top + peak, center.y), Vector3(a.x, top, a.y), Vector3(b.x, top, b.y), shade)

static func coil(tool: SurfaceTool) -> void:
	var outer: Array[Vector2] = polygon(6, Vector2.ONE * 0.82)
	var inner: Array[Vector2] = polygon(6, Vector2.ONE * 0.61)
	for i in range(6):
		var next: int = (i + 1) % 6
		var a := Vector3(outer[i].x, 0.8, outer[i].y)
		var b := Vector3(outer[next].x, 0.8, outer[next].y)
		var c := Vector3(inner[next].x, 0.8, inner[next].y)
		var d := Vector3(inner[i].x, 0.8, inner[i].y)
		quad(tool, a, b, c, d, 1)
		quad(tool, Vector3(a.x, 0.7, a.z), Vector3(b.x, 0.7, b.z), b, a, 0.72)
		quad(tool, Vector3(c.x, 0.7, c.z), Vector3(d.x, 0.7, d.z), d, c, 0.72)

static func quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, shade: float) -> void:
	triangle(tool, a, b, c, shade)
	triangle(tool, a, c, d, shade)

static func triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, shade: float) -> void:
	tool.set_normal((c - a).cross(b - a).normalized())
	tool.set_color(Color(shade, shade, shade, 1))
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)

extends RefCounted

# Original unit-sized triangular machine chip, shared by the existing FX pool.
static var shared_mesh: ArrayMesh
static var materials: Dictionary = {}

static func mesh() -> ArrayMesh:
	if shared_mesh != null:
		return shared_mesh
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(0, -0.5, -0.5)
	var b := Vector3(0.5, -0.5, 0.5)
	var c := Vector3(-0.5, -0.5, 0.5)
	var d := a + Vector3.UP
	var e := b + Vector3.UP
	var f := c + Vector3.UP
	triangle(tool, d, e, f, 1.0)
	triangle(tool, a, c, b, 0.36)
	quad(tool, a, b, e, d, 0.78)
	quad(tool, b, c, f, e, 0.58)
	quad(tool, c, a, d, f, 0.65)
	shared_mesh = tool.commit()
	return shared_mesh

static func material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var result: StandardMaterial3D = SwarmVisuals.material(color, true).duplicate()
		result.vertex_color_use_as_albedo = true
		result.vertex_color_is_srgb = true
		materials[color] = result
	return materials[color]

static func quad(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, shade: float) -> void:
	triangle(tool, a, b, c, shade)
	triangle(tool, a, c, d, shade)

static func triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, shade: float) -> void:
	tool.set_normal((c - a).cross(b - a).normalized())
	tool.set_color(Color(shade, shade, shade, 1))
	tool.add_vertex(a)
	tool.add_vertex(b)
	tool.add_vertex(c)

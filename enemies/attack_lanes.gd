extends RefCounted

# Original ground markings. Local -Z points toward the attack, with the same
# seven-metre base length/centre used by the existing warning transforms.
static var meshes: Dictionary = {}
static var materials: Dictionary = {}

static func create(parent: Node3D, behavior: int, color: Color) -> MeshInstance3D:
	if behavior not in [1, 2]:
		return SwarmVisuals.box(parent, Vector3(0.32, 0.04, 7.0), Vector3(0, 0.06, -3.5), color, true)
	var instance := MeshInstance3D.new()
	instance.name = "AttackLane"
	instance.mesh = mesh(behavior)
	instance.material_override = material(color)
	instance.position = Vector3(0, 0.06, -3.5)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)
	return instance

static func mesh(behavior: int) -> ArrayMesh:
	assert(behavior in [1, 2])
	if meshes.has(behavior):
		return meshes[behavior]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	if behavior == 1:
		# Broad paired rails and two unmistakably forward-pointing chevrons.
		for side in [-1.0, 1.0]:
			rectangle(tool, side * 0.48, 0.4, 0.12, 6.2, 0.6)
		for tip in [-3.5, -0.4]:
			quad(tool, Vector2(-0.54, tip + 0.8), Vector2(0, tip), Vector2(0, tip + 0.19), Vector2(-0.54, tip + 0.99), 1.0)
			quad(tool, Vector2(0, tip), Vector2(0.54, tip + 0.8), Vector2(0.54, tip + 0.99), Vector2(0, tip + 0.19), 1.0)
	else:
		# Sentry sight line: a slim shaft, two ticks and one solid arrowhead.
		rectangle(tool, 0, 0.4, 0.11, 6.2, 0.8)
		for at in [-0.5, 2.1]:
			rectangle(tool, 0, at, 0.5, 0.12, 0.65)
		triangle(tool, Vector2(0, -3.5), Vector2(0.4, -2.7), Vector2(-0.4, -2.7), 1.0)
	var result: ArrayMesh = tool.commit()
	meshes[behavior] = result
	return result

static func material(color: Color) -> StandardMaterial3D:
	if not materials.has(color):
		var result := StandardMaterial3D.new()
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		result.vertex_color_use_as_albedo = true
		result.vertex_color_is_srgb = true
		result.albedo_color = color
		materials[color] = result
	return materials[color]

static func rectangle(tool: SurfaceTool, x: float, z: float, width: float, length: float, shade: float) -> void:
	quad(tool, Vector2(x - width * 0.5, z - length * 0.5), Vector2(x + width * 0.5, z - length * 0.5), Vector2(x + width * 0.5, z + length * 0.5), Vector2(x - width * 0.5, z + length * 0.5), shade)

static func quad(tool: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, d: Vector2, shade: float) -> void:
	triangle(tool, a, b, c, shade)
	triangle(tool, a, c, d, shade)

static func triangle(tool: SurfaceTool, a: Vector2, b: Vector2, c: Vector2, shade: float) -> void:
	var p := Vector3(a.x, 0, a.y)
	var q := Vector3(b.x, 0, b.y)
	var r := Vector3(c.x, 0, c.y)
	# Godot front faces use clockwise winding, viewed from the camera above.
	if (r - p).cross(q - p).y < 0:
		var swap := q
		q = r
		r = swap
	tool.set_normal(Vector3.UP)
	tool.set_color(Color(shade, shade, shade, 1))
	tool.add_vertex(p)
	tool.add_vertex(q)
	tool.add_vertex(r)

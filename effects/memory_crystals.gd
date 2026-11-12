extends RefCounted

# Three bounded, shared, unlit memory tiers. No timers, RNG or extra draw layers.
static var meshes: Array[ArrayMesh] = []
static var materials: Array[StandardMaterial3D] = []

static func tier(xp: int) -> int:
	return 2 if xp >= 100 else (1 if xp >= 25 else 0)

static func mesh(xp: int) -> ArrayMesh:
	if meshes.is_empty():
		for sides in [4, 6, 8]:
			meshes.append(_build(sides))
	return meshes[tier(xp)]

static func material(xp: int) -> StandardMaterial3D:
	if materials.is_empty():
		for color in [Color("58d5ff"), Color("78f8d4"), Color("ffe39b")]:
			var surface := StandardMaterial3D.new()
			surface.albedo_color = color
			surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			surface.vertex_color_use_as_albedo = true
			surface.vertex_color_is_srgb = true
			materials.append(surface)
	return materials[tier(xp)]

static func _build(sides: int) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for i in range(sides):
		var a: float = TAU * i / sides
		var b: float = TAU * (i + 1) / sides
		var first := Vector3(cos(a), 0, sin(a)) * 0.16
		var second := Vector3(cos(b), 0, sin(b)) * 0.16
		# Godot front faces are clockwise. Flat grayscale facets retain the tier tint.
		for face in [[Vector3(0, 0.16, 0), first, second], [Vector3(0, -0.16, 0), second, first]]:
			var normal: Vector3 = (face[2] - face[0]).cross(face[1] - face[0]).normalized()
			var shade: float = (1.0 if i % 2 == 0 else 0.76) if normal.y > 0 else 0.56
			for point in face:
				vertices.append(point)
				normals.append(normal)
				colors.append(Color(shade, shade, shade, 1))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	var result := ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return result

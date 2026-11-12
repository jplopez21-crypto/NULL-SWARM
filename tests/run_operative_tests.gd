extends SceneTree

const MODEL = preload("res://effects/operative_model.gd")
const TRACE = preload("res://tests/operative_trace.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func inspect_mesh(id: String, triangles: int, surfaces: int) -> void:
	var mesh: ArrayMesh = MODEL.mesh(id)
	check(mesh == MODEL.mesh(id), id + " mesh is cached and shared")
	check(mesh.get_surface_count() == surfaces, id + " has bounded surface count")
	var total: int = 0
	var finite: bool = true
	var unit: bool = true
	var opaque: bool = true
	var nondegenerate: bool = true
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		check(vertices.size() > 0 and vertices.size() % 3 == 0 and vertices.size() == normals.size() and vertices.size() == colors.size(), id + " surface has complete triangle attributes")
		for i in range(vertices.size()):
			finite = finite and vertices[i].is_finite() and normals[i].is_finite()
			unit = unit and is_equal_approx(normals[i].length(), 1.0)
			opaque = opaque and colors[i].a == 1.0 and colors[i].r >= 0 and colors[i].r <= 1 and colors[i].g >= 0 and colors[i].g <= 1 and colors[i].b >= 0 and colors[i].b <= 1
		for i in range(0, vertices.size(), 3):
			nondegenerate = nondegenerate and (vertices[i + 1] - vertices[i]).cross(vertices[i + 2] - vertices[i]).length_squared() > 0.000000001
		total += vertices.size() / 3
		var material: StandardMaterial3D = mesh.surface_get_material(surface)
		check(material == MODEL.material(id == "visor" or (id == "rifle" and surface == 1)), id + " surface uses correct shared lit/energy material")
	check(total == triangles, id + " stays inside its triangle budget")
	check(finite and unit and nondegenerate, id + " geometry/normals are finite, unit and nondegenerate")
	check(opaque, id + " has opaque bounded vertex colors")

func run() -> void:
	inspect_mesh("armor", 152, 1)
	inspect_mesh("visor", 4, 1)
	inspect_mesh("leg", 48, 1)
	inspect_mesh("rifle", 44, 2)
	check(MODEL.meshes.size() == 4 and MODEL.materials.size() == 2, "four shared meshes and two materials bound resource growth")
	check(MODEL.material(false).shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL and MODEL.material(true).shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "armor is lit and only visor/rifle energy is unshaded")
	check(MODEL.mesh("armor").get_aabb().size.x <= 1.5 and MODEL.mesh("armor").get_aabb().end.y <= 1.83, "one-player armor stays within intended silhouette bounds")
	check(MODEL.mesh("leg").get_aabb().position.y == -0.25 and MODEL.mesh("leg").get_aabb().end.y == 0.25, "leg mesh retains the original animation pivot height")
	var a := SwarmPlayer.new()
	var b := SwarmPlayer.new()
	root.add_child(a)
	root.add_child(b)
	check(a.body.get_child_count() == 5 and b.body.get_child_count() == 5, "operative uses five mesh instances instead of seven box instances")
	check(a.legs.size() == 2 and a.legs[0] != b.legs[0] and a.legs[0].mesh == b.legs[0].mesh, "leg nodes are independent while geometry is shared")
	check(a.gun.position == Vector3(0.5, 1.0, -0.5) and a.gun is MeshInstance3D, "shaped rifle retains original recoil pivot")
	var fixed_pose: Transform3D = b.body.transform
	a.tick(0.1, Vector2.RIGHT, true)
	a.aim(Vector3.RIGHT)
	check(b.body.transform == fixed_pose and b.position == Vector3.ZERO and b.gun.position.z == -0.5, "one operative's animation cannot move another model")
	check(a.body.visible and a.health.invulnerable > 0 and a.dash_cooldown > 0, "armor remains visible during real dash protection")
	a.free()
	b.free()
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/operative-baseline.json"))
	var trace: Dictionary = TRACE.run(root)
	check(trace["fingerprint"] == baseline["fingerprint"] and trace["frames"] == 2400, "accepted-source full movement/health/aim/dash/animation trace remains identical")
	check(trace["accepted_dashes"] == baseline["accepted_dashes"] and trace["accepted_damage_events"] == baseline["accepted_damage_events"], "accepted dash/damage counts retain exact reference outcomes")
	QAReport.write("res://builds/qa/operative-tests.json", {"checks": checks, "failures": failures, "body_instances": 5, "body_surface_instances": 6, "body_triangles": 296, "previous_body_instances": 7, "previous_body_triangles": 84, "trace": trace, "scope": "Headless structural and simulation parity, not rendered FPS or human art acceptance."})
	print("OPERATIVE_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

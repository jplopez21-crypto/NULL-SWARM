extends SceneTree

const LANES = preload("res://enemies/attack_lanes.gd")
const ACCEPTED = preload("res://tests/fixtures/accepted_lane_enemy.gd")
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var geometry: Array = []
	for behavior in [1, 2]:
		var mesh: ArrayMesh = LANES.mesh(behavior)
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var triangles: int = 12 if behavior == 1 else 7
		check(mesh == LANES.mesh(behavior) and mesh.get_surface_count() == 1 and vertices.size() == triangles * 3, "warning mesh is cached with one bounded surface for behavior %d" % behavior)
		var valid := normals.size() == vertices.size() and colors.size() == vertices.size()
		for i in range(vertices.size()):
			# ArrayMesh octahedral normal encoding perturbs UP by about 0.000015.
			valid = valid and vertices[i].is_finite() and vertices[i].y == 0 and normals[i].distance_to(Vector3.UP) < 0.00003
			valid = valid and colors[i].a == 1 and colors[i].r >= 0.6 and colors[i].r <= 1 and colors[i].r == colors[i].g and colors[i].r == colors[i].b
		for i in range(0, vertices.size(), 3):
			valid = valid and (vertices[i + 2] - vertices[i]).cross(vertices[i + 1] - vertices[i]).y > 0.00001
		check(valid, "all warning triangles face above the floor with finite opaque geometry and no degenerate faces")
		check(is_equal_approx(mesh.get_aabb().position.z, -3.5) and is_equal_approx(mesh.get_aabb().end.z, 3.5), "warning retains exact seven-metre base length and attack-aligned centre")
		geometry.append({"behavior": behavior, "triangles": triangles, "width": mesh.get_aabb().size.x, "length": mesh.get_aabb().size.z})
	check(LANES.mesh(1) != LANES.mesh(2) and LANES.mesh(1).get_aabb().size.x > LANES.mesh(2).get_aabb().size.x, "charge has broad double chevrons while sentry has a distinct narrow sight line")
	var tint := Color("ff9274")
	var material: StandardMaterial3D = LANES.material(tint)
	check(material == LANES.material(tint) and material != SwarmVisuals.material(tint, true), "warning tint material is cached separately from unrelated effects")
	check(material.albedo_color == tint and material.vertex_color_use_as_albedo and material.vertex_color_is_srgb and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "warnings use definition tint, unshaded opaque surfaces and no new lighting or blending")
	check(not SwarmVisuals.material(tint, true).vertex_color_use_as_albedo, "warning material cannot change other shared visual materials")
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/accepted-lane-enemy.json"))
	check(FileAccess.get_file_as_string("res://tests/fixtures/accepted_lane_enemy.gd").sha256_text() == reference["fixture_sha256"], "paired accepted enemy reference is hash guarded")
	var cases: Array = []
	for kind in range(CombatWorld.DEFINITIONS.size()):
		var definition: EnemyDefinition = CombatWorld.DEFINITIONS[kind]
		var enemy := SwarmEnemy.new()
		root.add_child(enemy)
		enemy.configure(definition)
		var old: Node3D = ACCEPTED.new()
		root.add_child(old)
		old.configure(definition)
		check(enemy.get_child_count() == old.get_child_count() and enemy.body.get_child_count() == old.body.get_child_count(), "warning replacement adds no nodes or enemy body instances for %s" % definition.id)
		check(enemy.telegraph.position == old.telegraph.position and enemy.telegraph.visible == old.telegraph.visible and not enemy.telegraph.is_visible_in_tree() and not enemy.visible, "pool starts with identical warning transform and hidden state for %s" % definition.id)
		if kind in [1, 2]:
			check(enemy.telegraph.mesh == LANES.mesh(definition.behavior) and enemy.telegraph.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "actual warning instance uses cached directional ground mesh without shadows")
		else:
			check(enemy.telegraph.mesh is BoxMesh and enemy.telegraph.mesh.size == old.telegraph.mesh.size, "non-attacking archetypes retain their old hidden warning geometry")
		for multiplier in [1.0, 1.3]:
			for flashes in [false, true]:
				enemy.index = 7
				old.index = 7
				for sample in [enemy, old]:
					sample.activate(Vector3(2, 0, -3), 1.4)
					sample.movement_multiplier = multiplier
					sample.effects_enabled = flashes
				var exact := true
				var warning_frames := 0
				var shots := 0
				var charging_frames := 0
				for frame in range(480):
					if frame % 6 == 0:
						# Moving aim target checks locked warnings, staggered AI and turns.
						var aim := Vector3(2 + sin(frame * 0.01), 0, 3)
						enemy.think(aim)
						old.think(aim)
					if frame == 60:
						enemy.hit(2, Vector3(0.1, 0, -0.1))
						old.hit(2, Vector3(0.1, 0, -0.1))
					if frame == 180:
						enemy.exposed_time = 0.2
						old.exposed_time = 0.2
					var shot: Vector3 = enemy.tick(1.0 / 60.0)
					var old_shot: Vector3 = old.tick(1.0 / 60.0)
					exact = exact and shot == old_shot and snapshot(enemy) == snapshot(old)
					warning_frames += int(enemy.telegraph.visible)
					shots += int(shot != Vector3.ZERO)
					charging_frames += int(enemy.charging > 0)
				check(exact, "480 exact behavior/pose/visibility/transform steps match accepted %s / pace %s / flashes %s" % [definition.id, multiplier, flashes])
				if kind in [1, 2]:
					check(warning_frames > 0 and (charging_frames > 0 if kind == 1 else shots > 0), "real warning cycle reaches its unchanged charge/shot with reduced flashes %s" % not flashes)
				cases.append({"id": str(definition.id), "pace": multiplier, "flashes": flashes, "frames": 480, "exact_accepted_match": exact, "warning_frames": warning_frames, "shot_count": shots, "charging_frames": charging_frames})
		enemy.deactivate()
		enemy.activate(Vector3.ZERO, 1.0)
		check(not enemy.telegraph.visible and enemy.windup == 0 and enemy.charging == 0 and enemy.cooldown == 1.2, "pooled reuse clears warning and combat state for %s" % definition.id)
		enemy.free()
		old.free()
	QAReport.write("res://builds/qa/attack-lane-tests.json", {"checks": checks, "failures": failures, "geometry": geometry, "cases": cases, "reference": reference, "scope": "Geometry and exact same-worker accepted-enemy behavior pairs; no device FPS or human readability claim."})
	print("ATTACK_LANE_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func snapshot(enemy: Node3D) -> Array:
	return [enemy.active, enemy.visible, enemy.position, enemy.rotation, enemy.velocity, enemy.hp, enemy.max_hp, enemy.cooldown, enemy.windup, enemy.charging, enemy.flash, enemy.exposed_time, enemy.body.position, enemy.body.scale, enemy.body.visible, enemy.telegraph.visible, enemy.telegraph.position, enemy.telegraph.scale]

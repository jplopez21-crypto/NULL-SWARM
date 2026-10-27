class_name SwarmEnemy
extends Node3D

var active: bool = false
var definition: EnemyDefinition
var hp: float
var max_hp: float
var visual_scale: float = 1.0
var exposed_time: float = 0.0
var velocity: Vector3
var cooldown: float = 0.0
var windup: float = 0.0
var charging: float = 0.0
var flash: float = 0.0
var effects_enabled: bool = true
var body: Node3D
var telegraph: MeshInstance3D
var index: int = 0
var think_phase: int = 0
var movement_multiplier: float = 1.0

func configure(resource: EnemyDefinition) -> void:
	definition = resource
	body = Node3D.new()
	add_child(body)
	match definition.behavior:
		0:
			SwarmVisuals.box(body, Vector3(0.85, 0.55, 0.9), Vector3(0, 0.5, 0), definition.color)
			for side in [-1.0, 1.0]:
				SwarmVisuals.box(body, Vector3(0.22, 0.25, 1.2), Vector3(side * 0.55, 0.25, 0), Color("693537"))
		1:
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.0
			mesh.bottom_radius = 0.65
			mesh.height = 1.4
			mesh.radial_segments = 5
			var instance := MeshInstance3D.new()
			instance.mesh = mesh
			instance.position.y = 0.7
			instance.material_override = SwarmVisuals.material(definition.color)
			body.add_child(instance)
		2:
			SwarmVisuals.box(body, Vector3(1.2, 0.5, 1.2), Vector3(0, 0.3, 0), Color("49345e"))
			SwarmVisuals.box(body, Vector3(0.65, 1.2, 0.65), Vector3(0, 1.0, 0), definition.color)
		3:
			SwarmVisuals.box(body, Vector3(1.5, 1.2, 1.1), Vector3(0, 0.7, 0), Color("3f4a51"))
			SwarmVisuals.box(body, Vector3(1.65, 0.28, 0.22), Vector3(0, 1.1, -0.7), definition.color, true)
			for side in [-1.0, 1.0]:
				SwarmVisuals.box(body, Vector3(0.3, 0.8, 1.4), Vector3(side * 0.7, 0.4, 0), definition.color)
		4:
			SwarmVisuals.box(body, Vector3(1.6, 0.13, 0.38), Vector3(0, 1.1, 0), definition.color, true)
			SwarmVisuals.sphere(body, 0.42, Vector3(0, 1.1, 0), Color("456e8d"))
		5:
			SwarmVisuals.box(body, Vector3(0.85, 1.0, 0.85), Vector3(0, 0.7, 0), Color("48382c"))
			SwarmVisuals.ring(body, 0.85, Vector3(0, 0.7, 0), definition.color, 0.12)
			for side in [-1.0, 1.0]:
				SwarmVisuals.box(body, Vector3(0.18, 1.2, 0.22), Vector3(side * 0.55, 0.8, 0), definition.color, true)
	SwarmVisuals.box(body, Vector3(0.4, 0.15, 0.12), Vector3(0, 0.85, -0.52), definition.color.lightened(0.4), true)
	telegraph = SwarmVisuals.box(self, Vector3(0.32, 0.04, 7.0), Vector3(0, 0.06, -3.5), definition.color, true)
	deactivate()

func activate(at: Vector3, health_scale: float) -> void:
	position = at
	hp = definition.health * health_scale
	max_hp = hp
	velocity = Vector3.ZERO
	cooldown = 1.2
	windup = 0.0
	charging = 0.0
	flash = 0.0
	exposed_time = 0.0
	scale = Vector3.ONE
	body.position = Vector3.ZERO
	body.scale = Vector3.ONE * visual_scale
	body.visible = true
	telegraph.visible = false
	active = true
	visible = true

func deactivate() -> void:
	active = false
	visible = false

# Called in staggered batches at 10 Hz; movement stays at fixed tick frequency.
func think(player: Vector3) -> void:
	if exposed_time > 0.0:
		velocity = Vector3.ZERO
		return
	if windup > 0.0 or charging > 0.0:
		return
	var offset := player - position
	offset.y = 0.0
	var distance := offset.length()
	var direction := offset.normalized()
	rotation.y = atan2(-direction.x, -direction.z)
	if definition.behavior == 2 and distance < 15.0:
		velocity = Vector3.ZERO
		if cooldown <= 0.0:
			windup = 0.8
	elif definition.behavior == 1 and distance < 13.0 and cooldown <= 0.0:
		velocity = Vector3.ZERO
		windup = 0.7
	else:
		if definition.behavior == 4:
			direction = (direction + Vector3(-direction.z, 0, direction.x) * sin(cooldown * 2.5 + index) * 0.8).normalized()
		velocity = direction * definition.speed

# Returns a sentry shot direction only at the end of its visible warning.
func tick(delta: float) -> Vector3:
	exposed_time = maxf(0.0, exposed_time - delta)
	cooldown -= delta
	flash = maxf(0.0, flash - delta)
	var recoil: float = clampf(flash / 0.08, 0.0, 1.0) if effects_enabled else 0.0
	body.scale = Vector3(1.0 + recoil * 0.22, 1.0 - recoil * 0.18, 1.0 + recoil * 0.22) * visual_scale
	body.position.y = recoil * 0.10 * visual_scale
	var shot := Vector3.ZERO
	if definition.behavior == 1:
		var reach: float = 15.0 * 0.55 * movement_multiplier
		telegraph.scale.z = reach / 7.0
		telegraph.position.z = -reach * 0.5
	if windup > 0.0:
		windup -= delta
		telegraph.visible = true
		if windup <= 0.0:
			var forward := -transform.basis.z
			if definition.behavior == 1:
				velocity = forward * 15.0
				charging = 0.55
			else:
				shot = forward
			cooldown = 3.0
	else:
		telegraph.visible = false
	if charging > 0.0:
		charging -= delta
		if charging <= 0.0:
			velocity = Vector3.ZERO
	position += velocity * delta * movement_multiplier
	return shot

func hit(amount: float, knockback: Vector3) -> bool:
	hp -= maxf(0.0, amount)
	position += knockback
	flash = 0.08
	return hp <= 0.0

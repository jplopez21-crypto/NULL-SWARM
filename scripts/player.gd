class_name SwarmPlayer
extends Node3D

const DASH_COOLDOWN: float = 2.5
const DASH_DURATION: float = 0.18
const DASH_PROTECTION: float = 0.24
const DASH_SPEED: float = 27.0
var hit_ring: MeshInstance3D
var hit_feedback_time: float = 0.0
var health := HealthComponent.new()
var speed: float = 7.0
var walk_multiplier: float = 1.0
var magnet: float = 2.6
var dash_cooldown: float = 0.0
var dash_time: float = 0.0
var direction := Vector3(0, 0, -1)
var body: Node3D
var gun: Node3D
var boundary: float = 47.0
var stride: float = 0.0
var flash_feedback: bool = true
var recoil: float = 0.0
var legs: Array[MeshInstance3D] = []

func _ready() -> void:
	health.changed.connect(_damage_feedback)
	hit_ring = SwarmVisuals.ring(self, 1.0, Vector3(0, 0.10, 0), Color("5cbbf6"), 0.06)
	hit_ring.visible = false
	body = Node3D.new()
	add_child(body)
	SwarmVisuals.box(body, Vector3(0.85, 1.05, 0.65), Vector3(0, 0.85, 0), Color("264859"))
	SwarmVisuals.box(body, Vector3(0.66, 0.42, 0.65), Vector3(0, 1.58, 0), Color("80ffdb"), true)
	SwarmVisuals.box(body, Vector3(1.25, 0.3, 0.6), Vector3(0, 1.15, 0), Color("457b89"))
	for side in [-1.0, 1.0]:
		legs.append(SwarmVisuals.box(body, Vector3(0.27, 0.5, 0.3), Vector3(side * 0.25, 0.28, 0), Color("355966")))
	SwarmVisuals.ring(self, 0.8, Vector3(0, 0.06, 0), Color("5be8c5"), 0.035)
	SwarmVisuals.box(body, Vector3(0.75, 0.1, 0.12), Vector3(0, 1.58, -0.36), Color("e5fff5"), true)
	gun = SwarmVisuals.box(body, Vector3(0.23, 0.22, 1.0), Vector3(0.5, 1.0, -0.5), Color("d8fff1"), true)

func tick(delta: float, movement: Vector2, dash: bool) -> bool:
	health.tick(delta)
	stride += delta * movement.length() * 13.0
	recoil = maxf(0.0, recoil - delta * 5.0)
	gun.position.z = -0.5 + recoil * 0.2
	for i in range(legs.size()):
		legs[i].position.z = sin(stride + i * PI) * 0.2 * movement.length()
	body.position.y = absf(sin(stride)) * 0.06 * movement.length()
	body.rotation.z = lerpf(body.rotation.z, -movement.x * 0.08, 0.2)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	dash_time = maxf(0.0, dash_time - delta)
	var moving := Vector3(movement.x, 0, movement.y)
	if moving.length_squared() > 0.01:
		direction = moving.normalized()
	var dashed := false
	if dash and dash_cooldown <= 0.0:
		dash_time = DASH_DURATION
		dash_cooldown = DASH_COOLDOWN
		health.invulnerable = maxf(health.invulnerable, DASH_PROTECTION)
		dashed = true
	position += (direction * DASH_SPEED if dash_time > 0.0 else moving * effective_speed()) * delta
	position.x = clampf(position.x, -boundary, boundary)
	position.z = clampf(position.z, -boundary, boundary)
	# Keep the operative silhouette visible during both dash and hit protection.
	body.visible = true
	hit_feedback_time = maxf(0.0, hit_feedback_time - delta)
	hit_ring.visible = flash_feedback and hit_feedback_time > 0.0
	var expansion: float = 1.0 + (1.0 - hit_feedback_time / 0.35) * 0.4
	hit_ring.scale = Vector3(expansion, 0.5, expansion)
	return dashed

func effective_speed() -> float:
	return speed * walk_multiplier

func aim(target: Vector3) -> void:
	var offset := target - position
	if offset.length_squared() > 0.001:
		body.rotation.y = atan2(-offset.x, -offset.z)

func _exit_tree() -> void:
	for connection in health.depleted.get_connections():
		health.depleted.disconnect(connection["callable"])

func _damage_feedback() -> void:
	hit_feedback_time = 0.35
	var color := Color("5cbbf6") if health.last_hull_loss <= 0.0 else Color("ff9274")
	hit_ring.material_override = SwarmVisuals.material(color, true)
	hit_ring.scale = Vector3(1, 0.5, 1)
	hit_ring.visible = flash_feedback

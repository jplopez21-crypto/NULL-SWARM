class_name SwarmPlayer
extends Node3D

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
		dash_time = 0.18
		dash_cooldown = 2.5
		health.invulnerable = maxf(health.invulnerable, 0.24)
		dashed = true
	position += (direction * 27.0 if dash_time > 0.0 else moving * effective_speed()) * delta
	position.x = clampf(position.x, -boundary, boundary)
	position.z = clampf(position.z, -boundary, boundary)
	body.visible = not flash_feedback or health.invulnerable <= 0.0 or int(health.invulnerable * 20.0) % 2 == 0
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

class_name SwarmProjectile
extends Node3D

var active: bool = false
var hostile: bool = false
var velocity: Vector3
var damage: float
var remaining: float
var piercing: int
var struck: Array[int] = []
var visual: MeshInstance3D
var previous: Vector3

func configure(enemy_shot: bool) -> void:
	hostile = enemy_shot
	visual = SwarmVisuals.box(self, Vector3(0.18 if hostile else 0.1, 0.16, 0.6), Vector3(0, 0.8, 0), Color("f79bff") if hostile else Color("89ffe0"), true)
	deactivate()

func activate(at: Vector3, direction: Vector3, speed: float, amount: float, reach: float, pierce: int = 0) -> void:
	position = at
	previous = at
	velocity = direction.normalized() * speed
	rotation.y = atan2(-direction.x, -direction.z)
	damage = amount
	remaining = reach / speed
	piercing = pierce
	struck.clear()
	active = true
	visible = true

func tick(delta: float) -> void:
	previous = position
	position += velocity * delta
	remaining -= delta
	if remaining <= 0.0:
		deactivate()

func deactivate() -> void:
	active = false
	visible = false

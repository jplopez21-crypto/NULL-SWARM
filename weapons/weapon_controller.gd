class_name WeaponController
extends RefCounted

var definition: WeaponDefinition = preload("res://resources/pulse_rifle.tres")
var cooldown: float = 0.0
var damage: float = 18.0
var interval: float = 0.42
var piercing: int = 0

func ready_to_fire(delta: float, has_target: bool) -> bool:
	cooldown = maxf(0.0, cooldown - delta)
	if not has_target or cooldown > 0.0:
		return false
	cooldown = interval
	return true

func _init() -> void:
	damage = definition.damage
	interval = definition.cooldown
	piercing = definition.piercing

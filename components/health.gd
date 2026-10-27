class_name HealthComponent
extends RefCounted

signal changed
signal depleted
var maximum: float = 100.0
var current: float = 100.0
var shield: float = 30.0
var max_shield: float = 30.0
var invulnerable: float = 0.0
var recharge_delay: float = 0.0

func tick(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	recharge_delay = maxf(0.0, recharge_delay - delta)
	if recharge_delay <= 0.0:
		shield = minf(max_shield, shield + delta * 3.0)

func take_damage(amount: float) -> bool:
	if invulnerable > 0.0 or current <= 0.0 or amount <= 0.0:
		return false
	var absorbed: float = minf(shield, amount)
	shield -= absorbed
	current = maxf(0.0, current - (amount - absorbed))
	invulnerable = 0.8
	recharge_delay = 5.0
	changed.emit()
	if current <= 0.0:
		depleted.emit()
	return true

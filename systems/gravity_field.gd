class_name GravityField
extends Node3D

const RADIUS: float = 4.5
const DURATION: float = 1.5
const PULSE_INTERVAL: float = 0.3
const PULSE_DAMAGE_FRACTION: float = 0.09
const PULL_SPEED: float = 3.0
var remaining: float = 0.0
var age: float = 0.0
var next_pulse: float = PULSE_INTERVAL
var pulse_damage: float = 0.0
var activations: int = 0
var pulses_fired: int = 0
var pull_distance: float = 0.0
var core: MeshInstance3D

func _ready() -> void:
	SwarmVisuals.ring(self, RADIUS, Vector3(0, 0.10, 0), Arsenal.color("singularity"), 0.09)
	core = SwarmVisuals.ring(self, 0.65, Vector3(0, 0.14, 0), Color("9de9ff"), 0.15)
	visible = false

func activate(at: Vector3, damage_per_pulse: float) -> bool:
	if not at.is_finite() or not is_finite(damage_per_pulse) or damage_per_pulse <= 0:
		return false
	position = at
	if remaining <= 0.0:
		age = 0.0
		next_pulse = PULSE_INTERVAL
	remaining = DURATION
	pulse_damage = maxf(0.0, damage_per_pulse)
	activations += 1
	visible = true
	return true

# Manually ticked with combat: pause and visual quality cannot change damage clocks.
# Reindexes only enemies that cross a cell boundary; returns whether any moved.
func tick(delta: float, world: Node3D) -> bool:
	if not is_finite(delta) or remaining <= 0.0 or delta <= 0.0:
		return false
	var step: float = minf(delta, remaining)
	age += step
	remaining = maxf(0.0, remaining - step)
	if remaining < 0.000001:
		remaining = 0.0
	var candidates: Array = world.grid.query(position, RADIUS)
	var moved: bool = false
	for enemy in candidates:
		# Anchored bosses and committed attack lanes retain their advertised positions.
		if enemy.definition.radius >= 1.3 or enemy.windup > 0.0 or enemy.charging > 0.0:
			continue
		var offset: Vector3 = position - enemy.position
		offset.y = 0
		var distance: float = offset.length()
		if distance > 0.001:
			var travel: float = minf(distance, PULL_SPEED * step)
			var previous: Vector3 = enemy.position
			enemy.position += offset / distance * travel
			world.grid.relocate(enemy, previous)
			pull_distance += travel
			moved = true
	while next_pulse <= age + 0.000001:
		for enemy in candidates:
			world._damage(enemy, pulse_damage, Vector3.ZERO, false, "singularity")
		pulses_fired += 1
		next_pulse += PULSE_INTERVAL
	var radius: float = 0.75 + sin(age * 8.0) * 0.15 if world.effects_enabled else 1.0
	core.scale = Vector3(radius, 1, radius)
	visible = remaining > 0.0
	return moved

extends RefCounted

# Test-only read-only accumulator. Receives values; cannot steer or query the game.
var travel_m: float = 0.0
var active_seconds: float = 0.0
var dash_ready_seconds: float = 0.0
var steps: int = 0
var command_reversals: int = 0
var dash_requests: int = 0
var dash_activations: int = 0
var previous_direction := Vector2.ZERO
var before := Vector3.ZERO
var cooldown_before: float = 0.0
var request: bool = false
var active: bool = false

func begin_step(position: Vector3, movement: Vector2, requested: bool, cooldown: float, playing: bool) -> void:
	before = position
	cooldown_before = cooldown
	request = requested
	active = playing
	if not active:
		return
	if movement.length_squared() > 0.01:
		var direction := movement.normalized()
		if previous_direction.length_squared() > 0.0 and previous_direction.dot(direction) < -0.5:
			command_reversals += 1
		previous_direction = direction
	if requested:
		dash_requests += 1

func end_step(position: Vector3, cooldown: float, delta: float) -> void:
	if not active:
		return
	active = false
	var displacement := position - before
	displacement.y = 0.0
	travel_m += displacement.length()
	active_seconds += delta
	steps += 1
	# Player reduces cooldown before evaluating a request in the same tick.
	if cooldown_before <= delta:
		dash_ready_seconds += delta
	if request and cooldown > cooldown_before + 0.0001:
		dash_activations += 1

func snapshot(time: float) -> Dictionary:
	return {"time": snappedf(time, 0.01), "travel_m": snappedf(travel_m, 0.001),
		"active_seconds": snappedf(active_seconds, 0.001), "steps": steps,
		"command_reversals": command_reversals, "dash_requests": dash_requests,
		"dash_activations": dash_activations, "dash_ready_seconds": snappedf(dash_ready_seconds, 0.001)}

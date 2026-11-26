class_name FieldSentry
extends Node3D

const DURATION: float = 3.0
const RANGE_M: float = 14.0
const INTERVAL: float = 0.55
var enabled: bool = false
var remaining: float = 0.0
var attack_clock: float = 0.0
var activations: int = 0
var shots: int = 0
var head: Node3D

func _ready() -> void:
	visible = false

func configure(value: bool) -> void:
	enabled = value
	remaining = 0.0
	attack_clock = 0.0
	visible = false
	if enabled and head == null:
		# One reusable, original model. Other kits allocate no sentry meshes.
		for angle in [0.0, TAU / 3.0, TAU * 2.0 / 3.0]:
			var foot := SwarmVisuals.box(self, Vector3(0.22, 0.25, 1.05), Vector3(sin(angle) * 0.4, 0.15, cos(angle) * 0.4), Color("37624c"))
			foot.rotation.y = angle
		head = Node3D.new()
		add_child(head)
		SwarmVisuals.box(head, Vector3(0.8, 0.55, 0.65), Vector3(0, 0.65, 0), Color("37624c"))
		SwarmVisuals.box(head, Vector3(0.2, 0.18, 1.1), Vector3(0, 0.73, -0.5), Arsenal.color("drone"), true)
		SwarmVisuals.ring(self, 0.85, Vector3(0, 0.06, 0), Arsenal.color("drone"), 0.035)

func deploy(at: Vector3) -> bool:
	if not enabled or not at.is_finite():
		return false
	position = Vector3(at.x, 0, at.z)
	remaining = DURATION
	attack_clock = 0.0
	activations += 1
	visible = true
	return true

func tick(delta: float, world: CombatWorld) -> void:
	if not enabled or remaining <= 0.0:
		return
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0.00001:
		remaining = 0.0
		visible = false
		return
	var cycle_rate: float = (CombatWorld.OVERCLOCK_RATE if world.overclock > 0.0 else 1.0) * world.corruption.cycle_rate()
	attack_clock = maxf(0.0, attack_clock - delta * cycle_rate)
	if attack_clock > 0.0:
		return
	var rank: int = int(world.loadout.get("drone", 0))
	if rank <= 0:
		return
	var target: SwarmEnemy = world.grid.nearest(position, RANGE_M)
	if target == null:
		attack_clock = 0.1
		return
	var offset := target.position - position
	head.rotation.y = atan2(-offset.x, -offset.z)
	var damage: float = float(Arsenal.DATA["drone"]["damage"]) * (1.0 + (rank - 1) * 0.28)
	world.effects.emit_fx("beam", position + Vector3.UP * 0.7, target.position, Arsenal.color("drone"), 0.09)
	world._damage(target, damage, Vector3.ZERO, false, "drone")
	world.weapon_fired.emit("drone")
	shots += 1
	attack_clock = INTERVAL

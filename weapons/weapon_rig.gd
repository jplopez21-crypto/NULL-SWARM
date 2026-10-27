class_name WeaponRig
extends Node3D

var orbitals: Array[MeshInstance3D] = []
var drones: Array[Node3D] = []
var orbit_time: float = 0.0
var orbital_points: Array[Vector3] = []
var drone_points: Array[Vector3] = []

func _ready() -> void:
	for i in range(5):
		var mesh := SwarmVisuals.sphere(self, 0.32, Vector3.ZERO, Arsenal.color("orbit"))
		mesh.visible = false
		orbitals.append(mesh)
	for i in range(3):
		var drone := Node3D.new()
		add_child(drone)
		SwarmVisuals.box(drone, Vector3(0.5, 0.2, 0.7), Vector3.ZERO, Color("37624c"))
		SwarmVisuals.box(drone, Vector3(1.15, 0.08, 0.2), Vector3.ZERO, Arsenal.color("drone"), true)
		SwarmVisuals.sphere(drone, 0.16, Vector3(0, 0, -0.35), Arsenal.color("drone"))
		drone.visible = false
		drones.append(drone)

func tick(delta: float, at: Vector3, ranks: Dictionary, halo: bool) -> void:
	position = at
	orbit_time += delta
	var count: int = mini(5, int(ranks.get("orbit", 0)) + 1) if ranks.has("orbit") else 0
	orbital_points.clear()
	drone_points.clear()
	for i in range(orbitals.size()):
		orbitals[i].visible = i < count
		if i < count:
			var angle := orbit_time * (3.8 if halo else 2.6) + TAU * i / count
			orbitals[i].position = Vector3(cos(angle) * 3.2, 0.8, sin(angle) * 3.2)
			orbital_points.append(at + Vector3(cos(angle) * 3.2, 0, sin(angle) * 3.2))
	for i in range(drones.size()):
		var drone_count: int = 1 + int(ranks.get("drone", 0)) / 2 if ranks.has("drone") else 0
		drones[i].visible = i < drone_count
		if i < drone_count:
			var angle := orbit_time * 0.65 + i * TAU / drone_count
			drones[i].position = Vector3(cos(angle) * 2.3, 1.8 + sin(orbit_time * 3.0 + i) * 0.2, sin(angle) * 2.3)
			drone_points.append(at + Vector3(cos(angle) * 2.3, 0, sin(angle) * 2.3))

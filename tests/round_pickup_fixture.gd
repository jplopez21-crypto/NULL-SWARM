extends PickupSystem

# Presentation reference for the previous verified 8-segment/4-ring orb.
static var shape: SphereMesh

func _present(packet: MeshInstance3D, xp: int) -> void:
	if shape == null:
		shape = SphereMesh.new()
		shape.radius = 0.16
		shape.height = 0.32
		shape.radial_segments = 8
		shape.rings = 4
	packet.mesh = shape
	packet.scale = Vector3.ONE * clampf(1.0 + log(maxf(1.0, float(xp) / 5.0)) * 0.22, 1.0, 2.5)
	var color := Color("ffe39b") if xp >= 100 else (Color("78f8d4") if xp >= 25 else Color("58d5ff"))
	packet.material_override = SwarmVisuals.material(color, true)

class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var title: String
@export_enum("Pursue", "Charge", "Sentry", "Bulwark", "Skimmer", "Insulator") var behavior: int = 0
@export var health: float = 30.0
@export var speed: float = 3.0
@export var damage: float = 10.0
@export var xp: int = 5
# Preserve the existing fixed projectile/player collision margins. Updating a
# definition (including a live editor edit) invalidates both derived values.
var projectile_hit_radius_squared: float = pow(0.6 + 0.2, 2)
var player_contact_radius_squared: float = pow(0.6 + 0.45, 2)
@export var radius: float = 0.6:
	set(value):
		radius = value
		projectile_hit_radius_squared = pow(radius + 0.2, 2)
		player_contact_radius_squared = pow(radius + 0.45, 2)
@export var color: Color = Color("ff6655")

@export_range(0.0, 0.8, 0.05) var electric_resistance: float = 0.0

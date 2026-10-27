class_name EnemyDefinition
extends Resource

@export var id: StringName
@export var title: String
@export_enum("Pursue", "Charge", "Sentry") var behavior: int = 0
@export var health: float = 30.0
@export var speed: float = 3.0
@export var damage: float = 10.0
@export var xp: int = 5
@export var radius: float = 0.6
@export var color: Color = Color("ff6655")

class_name ReactorArena
extends Node3D

const DECK_PANELS = preload("res://environments/deck_panels.gd")

var reactor: Node3D
var clock_time: float = 0.0

func _ready() -> void:
	SwarmVisuals.box(self, Vector3(100, 0.4, 100), Vector3(0, -0.3, 0), Color("0b1823"))
	for parity in range(2):
		var instance := MultiMeshInstance3D.new()
		instance.name = "DeckPanels%d" % parity
		var batch := MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = DECK_PANELS.mesh(parity)
		batch.instance_count = 200
		var idx: int = 0
		for x in range(20):
			for z in range(20):
				if (x + z) % 2 == parity:
					batch.set_instance_transform(idx, Transform3D(Basis(), Vector3(x * 5 - 47.5, -0.08, z * 5 - 47.5)))
					idx += 1
		instance.multimesh = batch
		instance.material_override = DECK_PANELS.material()
		instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(instance)
	for side in [-1.0, 1.0]:
		SwarmVisuals.box(self, Vector3(96, 0.08, 0.13), Vector3(0, 0, side * 47.8), Color("5be8c5"), true)
		SwarmVisuals.box(self, Vector3(0.13, 0.08, 96), Vector3(side * 47.8, 0, 0), Color("5be8c5"), true)
		for i in range(-9, 10):
			SwarmVisuals.box(self, Vector3(2.0, 0.04, 0.5), Vector3(i * 5, 0.03, side * 45.0), Color("83734b"), true).rotation.y = 0.45
	for i in range(8):
		var angle := float(i) * TAU / 8
		var at := Vector3(cos(angle) * 61, 0, sin(angle) * 61)
		SwarmVisuals.box(self, Vector3(7, 2, 7), at + Vector3(0, 1, 0), Color("253946"))
		SwarmVisuals.box(self, Vector3(4.5, 11, 4.5), at + Vector3(0, 6, 0), Color("1a2d3a"))
		SwarmVisuals.box(self, Vector3(4.7, 0.2, 4.7), at + Vector3(0, 9, 0), Color("5be8c5"), true)
		for stripe in range(3):
			SwarmVisuals.box(self, Vector3(0.24, 5, 4.7), at + Vector3(stripe - 1, 5, 0), Color("41778c"), true)
	reactor = Node3D.new()
	add_child(reactor)
	SwarmVisuals.ring(reactor, 7.0, Vector3(0, 0.02, 0), Color("286875"), 0.08)
	SwarmVisuals.ring(reactor, 5.0, Vector3(0, 0.03, 0), Color("276a71"), 0.06)
	for i in range(8):
		var angle := i * TAU / 8
		var pad := SwarmVisuals.box(reactor, Vector3(0.4, 0.03, 1.7), Vector3(cos(angle) * 6.0, 0.03, sin(angle) * 6.0), Color("4a9b9d"), true)
		pad.rotation.y = -angle + PI / 2
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("07111c")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("abc5d7")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-65, -25, 0)
	light.light_color = Color("b6d4e7")
	light.light_energy = 1.5
	light.shadow_enabled = false
	add_child(light)

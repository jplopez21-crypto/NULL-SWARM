class_name SwarmAudio
extends Node

var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var cursor: int = 0
var music: AudioStreamPlayer

func _ready() -> void:
	for bus_name in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")
	for i in range(12):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)
	for spec in [["fire", 460.0, 0.07], ["hit", 170.0, 0.08], ["kill", 95.0, 0.14], ["level", 720.0, 0.35], ["damage", 65.0, 0.25], ["ui", 520.0, 0.08], ["dash", 300.0, 0.16]]:
		sounds[spec[0]] = tone(spec[1], spec[2])
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.volume_db = -20.0
	var drone := tone(55.0, 4.0, true)
	drone.loop_mode = AudioStreamWAV.LOOP_FORWARD
	drone.loop_end = drone.data.size() / 2
	music.stream = drone
	add_child(music)
	music.play()

func tone(hz: float, duration: float, ambient: bool = false) -> AudioStreamWAV:
	var rate: int = 22050
	var bytes := PackedByteArray()
	bytes.resize(int(rate * duration) * 2)
	for i in range(bytes.size() / 2):
		var time := float(i) / rate
		var envelope := 0.4 if ambient else pow(1.0 - time / duration, 2.0)
		var phase := TAU * hz * time * (1.0 if ambient else 1.0 - time / duration * 0.4)
		var sample := (sin(phase) + sin(phase * 2.0) * 0.2) * envelope * 0.35
		bytes.encode_s16(i * 2, int(sample * 32767.0))
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = rate
	result.data = bytes
	return result

func play(id: String, bus: String = "SFX") -> void:
	if not sounds.has(id):
		return
	var voice := voices[cursor % voices.size()]
	cursor += 1
	voice.bus = bus
	voice.stream = sounds[id]
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.volume_db = -12.0
	voice.play()

func apply(settings: Dictionary) -> void:
	for pair in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"], ["UI", "ui"]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(pair[0]), linear_to_db(maxf(0.0001, float(settings[pair[1]]))))

func shutdown() -> void:
	# Release playbacks before the audio server shuts down, including dummy/headless audio.
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	if is_instance_valid(music):
		music.stop()
		music.stream = null
	sounds.clear()

func _exit_tree() -> void:
	shutdown()

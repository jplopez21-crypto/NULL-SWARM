class_name SwarmAudio
extends Node

var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var cursor: int = 0
var last_played: Dictionary = {}
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
	for spec in [["fire", 460.0, 0.07], ["hit", 170.0, 0.08], ["kill", 95.0, 0.14], ["level", 720.0, 0.35], ["damage", 65.0, 0.25], ["ui", 520.0, 0.08], ["dash", 300.0, 0.16], ["orbit", 260.0, 0.10], ["arc", 1120.0, 0.15], ["rail", 85.0, 0.3], ["thermal", 52.0, 0.32], ["drone", 680.0, 0.06]]:
		sounds[spec[0]] = tone(spec[1], spec[2])
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.volume_db = -20.0
	var drone := score_loop()
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
	result.stereo = false
	result.data = bytes
	return result

func play(id: String, bus: String = "SFX") -> void:
	var now: int = Time.get_ticks_msec()
	if now - int(last_played.get(id, -1000)) < 65:
		return
	last_played[id] = now
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

func score_loop() -> AudioStreamWAV:
	# Original eight-second sequencer: bass ostinato, soft kick and high pulse.
	var rate: int = 22050
	var bytes := PackedByteArray()
	bytes.resize(rate * 8 * 2)
	var notes: Array[float] = [55.0, 55.0, 65.406, 49.0, 55.0, 73.416, 65.406, 49.0]
	for i in range(rate * 8):
		var t := float(i) / rate
		var step: int = int(t * 4.0)
		var gate := fmod(t, 0.25)
		var bass: float = sin(TAU * notes[(step / 4) % 8] * t) * exp(-gate * 13.0) * 0.30
		var kick_t := fmod(t, 0.5)
		var kick := sin(TAU * (45.0 * kick_t + 3.0 * (1.0 - exp(-kick_t * 35.0)))) * exp(-kick_t * 24.0) * 0.28
		var pulse := sin(TAU * 440.0 * t) * exp(-gate * 70.0) * 0.04
		var pad := sin(TAU * 110.0 * t) * 0.04 + sin(TAU * 164.8125 * t) * sin(PI * t / 8.0) * 0.025
		bytes.encode_s16(i * 2, int(clampf(bass + kick + pulse + pad, -0.95, 0.95) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	# Godot WAV mixing uses an inclusive end sample, not a frame count.
	stream.loop_end = bytes.size() / 2 - 1
	return stream

class_name SwarmAudio
extends Node

const MEMORY_INTERVAL_MS: int = 140
const PRIORITY_VOICES: int = 2
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var cursor: int = 0
var last_played: Dictionary = {}
var last_dispatched: Dictionary = {}
var dropped_cues: int = 0
var music: AudioStreamPlayer
var memory_voice: AudioStreamPlayer
var memory_plays: int = 0
var memory_next_ms: int = 0

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
	for spec in [["fire", 460.0, 0.07], ["hit", 170.0, 0.08], ["level", 720.0, 0.35], ["damage", 65.0, 0.25], ["shield", 880.0, 0.12], ["ui", 520.0, 0.08], ["dash", 300.0, 0.16], ["orbit", 260.0, 0.10], ["arc", 1120.0, 0.15], ["rail", 85.0, 0.3], ["singularity", 140.0, 0.32], ["thermal", 52.0, 0.32], ["drone", 680.0, 0.06]]:
		sounds[spec[0]] = tone(spec[1], spec[2])
	sounds["kill"] = destruction_crunch()
	memory_voice = AudioStreamPlayer.new()
	memory_voice.bus = "SFX"
	memory_voice.volume_db = -18.0
	memory_voice.stream = memory_chime()
	add_child(memory_voice)
	music = AudioStreamPlayer.new()
	sounds["sentry"] = tone(760.0, 0.22)
	music.bus = "Music"
	music.volume_db = -20.0
	var drone := score_loop()
	music.stream = drone
	add_child(music)
	# Start on the first process tick so same-frame scene teardown can cancel it.
	# Registering then stopping a WAV before the audio thread sees it leaks playback.
	set_process(true)

func _process(_delta: float) -> void:
	set_process(false)
	if is_instance_valid(music) and music.stream != null:
		music.play()

func tone(hz: float, duration: float, ambient: bool = false) -> AudioStreamWAV:
	var rate: int = 22050
	var bytes := PackedByteArray()
	bytes.resize(int(rate * duration) * 2)
	for i in range(bytes.size() / 2):
		var time := float(i) / rate
		var fraction: float = float(i) / maxf(1.0, bytes.size() / 2 - 1)
		var envelope: float = (0.4 if ambient else pow(1.0 - fraction, 2.0)) * minf(1.0, time / 0.004) * minf(1.0, (1.0 - fraction) * duration / 0.004)
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
	# Keep the existing random-draw budget even when a saturated pool drops a cue.
	var pitch: float = randf_range(0.94, 1.06)
	var priority: bool = bus == "UI" or id in ["damage", "shield", "level", "dash"]
	var voice: AudioStreamPlayer = null
	if priority:
		for i in range(maxi(0, voices.size() - PRIORITY_VOICES), voices.size()):
			if not voices[i].playing:
				voice = voices[i]
				break
	if voice == null:
		var available: int = maxi(0, voices.size() - PRIORITY_VOICES)
		for offset in range(available):
			var index: int = (cursor + offset) % available
			if not voices[index].playing:
				voice = voices[index]
				cursor += offset + 1
				break
	if voice == null:
		dropped_cues += 1
		return # Never hard-cut a playing waveform or queue delayed combat sounds.
	voice.bus = bus
	voice.stream = sounds[id]
	voice.pitch_scale = pitch
	voice.volume_db = -12.0
	voice.play()
	last_dispatched[id] = now

func apply(settings: Dictionary) -> void:
	for pair in [["Master", "master"], ["Music", "music"], ["SFX", "sfx"], ["UI", "ui"]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(pair[0]), linear_to_db(maxf(0.0001, float(settings[pair[1]]))))

# One call for the actual XP total collected this tick, never one per packet.
# A dedicated voice cannot steal a weapon/damage/UI cue or grow a playback queue.
func memory_collected(amount: int, levelled: bool = false) -> bool:
	if amount <= 0 or levelled or not is_instance_valid(memory_voice) or memory_voice.stream == null:
		return false
	var now: int = Time.get_ticks_msec()
	if now < memory_next_ms or memory_voice.playing:
		return false
	memory_next_ms = now + MEMORY_INTERVAL_MS
	memory_voice.pitch_scale = [1.0, 1.122462, 1.259921][2 if amount >= 100 else (1 if amount >= 25 else 0)]
	memory_voice.play()
	memory_plays += 1
	return true

func reset_memory_feedback() -> void:
	memory_plays = 0
	memory_next_ms = 0
	if is_instance_valid(memory_voice):
		memory_voice.stop()

func memory_chime() -> AudioStreamWAV:
	# Original 90ms two-partial rising cue, with click-free attack and release.
	var rate: int = 22050
	var frames: int = int(rate * 0.09)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	for i in range(frames):
		var t := float(i) / rate
		var fraction := float(i) / (frames - 1)
		var delayed: float = maxf(0.0, t - 0.022)
		var envelope: float = minf(1.0, t / 0.004) * pow(1.0 - fraction, 2.0)
		var fundamental: float = sin(TAU * (880.0 * t + 200.0 * t * t)) * 0.16
		var overtone: float = sin(TAU * (1320.0 * delayed + 300.0 * delayed * delayed)) * minf(1.0, delayed / 0.004) * 0.06
		bytes.encode_s16(i * 2, int((fundamental + overtone) * envelope * 32767.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = rate
	clip.stereo = false
	clip.data = bytes
	return clip

func destruction_crunch() -> AudioStreamWAV:
	# Original 140ms mechanical breakup: three noise transients and metal partials.
	# Local integer noise never consumes the global/gameplay RNG stream.
	var rate: int = 22050
	var frames: int = int(rate * 0.14)
	var bytes := PackedByteArray()
	bytes.resize(frames * 2)
	var noise_state: int = 0x4e554c4c
	var low: float = 0.0
	var starts: Array[float] = [0.0, 0.027, 0.056]
	var weights: Array[float] = [1.0, 0.55, 0.25]
	for i in range(frames):
		noise_state = (noise_state ^ (noise_state << 13)) & 0xffffffff
		noise_state = (noise_state ^ (noise_state >> 17)) & 0xffffffff
		noise_state = (noise_state ^ (noise_state << 5)) & 0xffffffff
		var white: float = float(noise_state & 0xffff) / 32767.5 - 1.0
		low += (white - low) * 0.24
		var t: float = float(i) / rate
		var fraction: float = float(i) / (frames - 1)
		var burst: float = 0.0
		for j in range(starts.size()):
			var dt: float = t - starts[j]
			if dt >= 0:
				burst += weights[j] * minf(1.0, dt / 0.002) * exp(-dt * 95.0)
		var body: float = sin(TAU * (130.0 * t - 160.0 * t * t)) * exp(-t * 32.0) * 0.18
		var metal: float = (sin(TAU * 1110.0 * t) + sin(TAU * 1730.0 * t) * 0.5) * exp(-t * 55.0) * 0.035
		var envelope: float = minf(1.0, t / 0.002) * pow(1.0 - fraction, 2.0)
		var sample: float = ((white - low * 0.7) * burst * 0.23 + body + metal) * envelope
		bytes.encode_s16(i * 2, int(sample * 32767.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = rate
	clip.stereo = false
	clip.data = bytes
	return clip

func shutdown() -> void:
	# Cancel startup as well as already running playback.
	set_process(false)
	reset_memory_feedback()
	if is_instance_valid(memory_voice):
		memory_voice.stream = null
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
	var bass_phase: float = 0.0
	for i in range(rate * 8):
		var t := float(i) / rate
		var step: int = int(t * 4.0)
		var gate := fmod(t, 0.25)
		# Continuous oscillator phase plus short beat-edge fades prevent step clicks.
		var beat_envelope: float = minf(1.0, gate / 0.006) * minf(1.0, (0.25 - gate) / 0.008)
		var bass: float = sin(bass_phase) * exp(-gate * 13.0) * beat_envelope * 0.30
		bass_phase = fmod(bass_phase + TAU * notes[(step / 4) % 8] / rate, TAU)
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

extends SceneTree

var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var builder := SwarmAudio.new()
	var music: AudioStreamWAV = builder.score_loop()
	var frames: int = music.data.size() / 2
	check(music.format == AudioStreamWAV.FORMAT_16_BITS and not music.stereo, "procedural music declares mono sixteen-bit PCM")
	check(frames == music.mix_rate * 8 and is_equal_approx(music.get_length(), 8), "music contains exactly eight seconds of PCM")
	check(music.loop_mode == AudioStreamWAV.LOOP_FORWARD and music.loop_begin == 0 and music.loop_end == frames - 1, "loop end is the last valid sample, never one-past-buffer")
	var playback: AudioStreamPlayback = music.instantiate_playback()
	playback.start()
	var remaining: int = int(AudioServer.get_mix_rate()) * 24
	var finite_samples: bool = true
	while remaining > 0:
		var count: int = mini(1024, remaining)
		var mixed: PackedVector2Array = playback.mix_audio(1.0, count)
		finite_samples = finite_samples and mixed.size() == count
		for frame in mixed:
			finite_samples = finite_samples and frame.is_finite() and absf(frame.x) <= 1.0 and absf(frame.y) <= 1.0
		remaining -= count
	check(finite_samples, "twenty-four seconds of offline looping/resampling remain finite and in range")
	check(playback.is_playing() and playback.get_playback_position() >= 0 and playback.get_playback_position() <= music.get_length(), "playback remains valid across multiple loop boundaries")
	playback.stop()
	playback = null
	music = null
	var tone: AudioStreamWAV = builder.tone(460, 0.07)
	check(tone.loop_mode == AudioStreamWAV.LOOP_DISABLED and not tone.stereo and tone.data.size() > 0, "one-shot effects stay non-looping mono PCM")
	tone = null
	builder.free()
	await process_frame
	QAReport.write("res://builds/qa/audio-tests.json", {"checks": checks, "failures": failures})
	print("AUDIO_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

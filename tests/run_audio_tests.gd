extends SceneTree

var checks: int = 0
var failures: Array[String] = []
var memory_receipt: Dictionary = {}

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
	var memory_clip: AudioStreamWAV = builder.memory_chime()
	check(memory_clip.format == AudioStreamWAV.FORMAT_16_BITS and not memory_clip.stereo and memory_clip.mix_rate == 22050 and memory_clip.loop_mode == AudioStreamWAV.LOOP_DISABLED, "memory cue is bounded non-looping mono PCM")
	check(is_equal_approx(memory_clip.get_length(), float(int(22050 * 0.09)) / 22050) and memory_clip.data == builder.memory_chime().data, "memory cue is deterministic and ninety milliseconds long")
	var peak: float = 0
	var dc: float = 0
	var energy: float = 0
	var max_step: float = 0
	var last_sample: float = 0
	for i in range(memory_clip.data.size() / 2):
		var sample: float = memory_clip.data.decode_s16(i * 2) / 32768.0
		peak = maxf(peak, absf(sample))
		dc += sample
		energy += sample * sample
		max_step = maxf(max_step, absf(sample - last_sample))
		last_sample = sample
	var count: int = memory_clip.data.size() / 2
	check(peak > 0.05 and peak < 0.22 and sqrt(energy / count) > 0.02 and absf(dc / count) < 0.002, "memory PCM is non-silent, quiet, unclipped and free of significant DC offset")
	check(memory_clip.data.decode_s16(0) == 0 and memory_clip.data.decode_s16(memory_clip.data.size() - 2) == 0 and max_step < 0.08, "memory cue has smooth zero-ended attack/release without discontinuities")
	check(memory_clip.save_to_wav("res://builds/qa/memory-cue.wav") == OK, "original memory cue exported for human listening review")
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(memory_clip.data)
	memory_receipt = {"raw_pcm_sha256": digest.finish().hex_encode(), "duration_seconds": memory_clip.get_length(), "sample_rate": memory_clip.mix_rate, "mono": not memory_clip.stereo, "peak": peak, "rms": sqrt(energy / count), "dc_offset": dc / count, "largest_sample_step": max_step, "minimum_interval_ms": SwarmAudio.MEMORY_INTERVAL_MS, "combat_voices": 12, "dedicated_memory_voices": 1, "limits": "Offline PCM/playback/routing and game integration checks; no human listening or phone speaker mix acceptance."}
	memory_clip = null
	builder.free()
	var cancelled := SwarmAudio.new()
	root.add_child(cancelled)
	check(not cancelled.music.playing and cancelled.is_processing(), "music waits until the first process tick")
	cancelled.shutdown()
	await process_frame
	check(not cancelled.is_processing() and cancelled.music.stream == null, "same-frame shutdown cancels pending music startup")
	cancelled.queue_free()
	var started := SwarmAudio.new()
	root.add_child(started)
	await process_frame
	await process_frame
	check(started.music.playing and not started.is_processing(), "normal scene starts music once on its first tick")
	check(started.voices.size() == 12 and not started.voices.has(started.memory_voice) and started.memory_voice.bus == "SFX" and started.memory_voice.volume_db == -18, "memory feedback has one dedicated quiet voice without reducing the twelve combat voices")
	check(not started.memory_collected(0) and not started.memory_collected(-5) and not started.memory_collected(25, true) and started.memory_plays == 0, "zero/invalid XP and level-up batches cannot start a collection cue")
	started.play("fire")
	var cursor: int = started.cursor
	check(started.memory_collected(5) and started.memory_plays == 1 and started.memory_voice.playing and started.memory_voice.pitch_scale == 1.0, "real collection starts the low-tier cue once")
	check(started.cursor == cursor and started.voices[0].playing, "memory cue cannot steal or repoint an active weapon voice")
	var deadline: int = started.memory_next_ms
	started.memory_next_ms = Time.get_ticks_msec() + 60000
	var rejected := true
	for i in range(100):
		rejected = rejected and not started.memory_collected(1000000)
	check(rejected and started.memory_plays == 1 and started.memory_voice.pitch_scale == 1.0, "vacuum/high-value bursts cannot bypass the common rate limit or build a queue")
	started.memory_next_ms = deadline
	await create_timer(0.16).timeout
	check(not started.memory_voice.playing and started.memory_plays == 1, "collection bursts leave no looping or deferred audio after the short clip")
	check(started.memory_collected(25) and is_equal_approx(started.memory_voice.pitch_scale, 1.122462), "expired cooldown permits the middle batch pitch")
	await create_timer(0.16).timeout
	check(started.memory_collected(100) and is_equal_approx(started.memory_voice.pitch_scale, 1.259921), "high-value batches use a bounded higher pitch")
	var preferences: Dictionary = SaveStore.defaults()["settings"]
	preferences["sfx"] = 0.0
	started.apply(preferences)
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(started.memory_voice.bus)) <= -79, "existing SFX zero-volume setting attenuates the dedicated memory voice")
	preferences["sfx"] = 0.8
	started.apply(preferences)
	await create_timer(0.16).timeout
	started.reset_memory_feedback()
	check(started.memory_plays == 0 and started.memory_next_ms == 0 and not started.memory_voice.playing, "fresh deployment resets feedback counter, cooldown and playback")
	started.shutdown()
	check(not started.memory_collected(5) and started.memory_voice.stream == null, "shutdown rejects collection feedback and releases its stream")
	await create_timer(0.20).timeout
	started.queue_free()
	await process_frame
	var immediate := SwarmAudio.new()
	root.add_child(immediate)
	immediate.memory_collected(5)
	immediate.shutdown()
	immediate.queue_free()
	await create_timer(0.20).timeout
	check(not is_instance_valid(immediate), "same-frame collection/shutdown releases the node before strict engine-leak scan")
	await _test_collection_integration()
	QAReport.write("res://builds/qa/audio-tests.json", {"checks": checks, "failures": failures, "memory_cue": memory_receipt})
	print("AUDIO_RESULT checks=", checks, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)

func _test_collection_integration() -> void:
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.save.path = "user://qa_memory_audio.json"
	game.save.data = SaveStore.defaults()
	game.start_run()
	for amount in [1, 2, 2]:
		game.pickups.drop(game.player.position, amount)
	game._physics_process(1.0 / 60)
	check(game.pickups.total_collected == 5 and game.progress.xp == 5 and game.audio.memory_plays == 1, "real physics collection aggregates three packets into one cue and grants exact XP")
	game.pause_run()
	game.pickups.drop(game.player.position, 4)
	game._physics_process(1)
	check(game.progress.xp == 5 and game.pickups.outstanding_xp() == 4 and game.audio.memory_plays == 1, "paused gameplay cannot collect memory or start its cue")
	game.resume_run()
	game.audio.memory_next_ms = Time.get_ticks_msec() + 60000
	game._physics_process(1.0 / 60)
	check(game.progress.xp == 9 and game.pickups.total_collected == 9 and game.audio.memory_plays == 1, "suppressed audio never discards or delays XP")
	game.audio.memory_next_ms = 0
	game._physics_process(1.0 / 60)
	check(game.audio.memory_plays == 1, "empty physics ticks cannot play a previously suppressed collection batch")
	game.pickups.drop(game.player.position, 100)
	game._physics_process(1.0 / 60)
	check(game.state == game.State.UPGRADING and game.progress.pending == 3 and game.audio.memory_plays == 1, "real multi-level overflow gives priority to level-up audio without changing the upgrade queue")
	game.start_run()
	check(game.audio.memory_plays == 0 and game.audio.memory_next_ms == 0 and game.progress.level == 1, "ordinary restart resets feedback and run progression together")
	game.audio.shutdown()
	await create_timer(0.20).timeout
	game.queue_free()
	await process_frame

extends SceneTree

const FRAGMENTS = preload("res://effects/debris_fragment.gd")
const LEGACY = preload("res://tests/box_destruction_fixture.gd")
const TRACE = preload("res://tests/destruction_trace.gd")
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
	var mesh: ArrayMesh = FRAGMENTS.mesh()
	check(mesh == FRAGMENTS.mesh() and mesh.get_surface_count() == 1, "one fragment mesh is cached across runs and pool slots")
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	check(vertices.size() == 24 and normals.size() == 24 and colors.size() == 24, "fragment uses eight complete triangles instead of twelve")
	var finite := true
	var unit := true
	var area := true
	var opaque := true
	for i in range(vertices.size()):
		finite = finite and vertices[i].is_finite() and normals[i].is_finite()
		unit = unit and is_equal_approx(normals[i].length(), 1.0)
		opaque = opaque and colors[i].a == 1 and colors[i].r >= 0.35 and colors[i].r <= 1 and colors[i].r == colors[i].g and colors[i].g == colors[i].b
	for i in range(0, vertices.size(), 3):
		area = area and (vertices[i + 1] - vertices[i]).cross(vertices[i + 2] - vertices[i]).length_squared() > 0.001
	check(finite and unit and area, "fragment geometry is finite/nondegenerate with unit normals")
	check(opaque, "opaque bounded grayscale facets preserve definition tint")
	check(mesh.get_aabb() == AABB(Vector3.ONE * -0.5, Vector3.ONE), "fragment retains original unit bounds before unchanged effect scaling")
	var color := Color("ff9274").lightened(0.2)
	var material: StandardMaterial3D = FRAGMENTS.material(color)
	check(material == FRAGMENTS.material(color) and material != SwarmVisuals.material(color, true), "fragment reuses a separate cached tint material")
	check(material.albedo_color == color and material.vertex_color_use_as_albedo and material.vertex_color_is_srgb and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "facets use shared unshaded vertex tint without lights")
	check(not SwarmVisuals.material(color, true).vertex_color_use_as_albedo, "fragment material cannot alter shared beam/ring material settings")
	for quality in range(3):
		for flashes in [false, true]:
			var fx := CombatEffects.new()
			root.add_child(fx)
			fx.quality = quality
			fx.flashes = flashes
			fx.destruction(Vector3.ZERO, Color("ff9274"), false)
			var count: int = [2, 4, 6][quality] if flashes else 0
			check(fx.live.size() == count + 1 and fx.pool.size() + fx.live.size() == 160, "regular destruction retains original count/pool at quality %d flashes %s" % [quality, flashes])
			var correct := true
			for item in fx.live:
				if item["kind"] == "shard":
					correct = correct and item["mesh"].mesh == mesh and item["mesh"].material_override == material and item["duration"] == 0.65
			check(correct, "only fragment slots use new cached geometry/material with unchanged duration")
			fx.tick(10)
			fx.destruction(Vector3.ZERO, Color("ff9274"), true)
			check(fx.live.size() == count * 2 + 1, "large destruction retains original count at quality %d flashes %s" % [quality, flashes])
			fx.tick(10)
			fx.emit_fx("beam", Vector3.ZERO, Vector3.RIGHT, Color.WHITE)
			fx.emit_fx("dash", Vector3.ZERO, Vector3.RIGHT, Color.WHITE)
			check(fx.live[0]["mesh"].mesh == fx.beam_mesh and (not flashes or fx.live[1]["mesh"].mesh == fx.beam_mesh), "beam and dash keep their original box geometry")
			fx.tick(10)
			check(fx.live.is_empty() and fx.pool.size() == 160, "all geometry types recycle into the original fixed pool")
			fx.free()
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/destruction-baseline.json"))
	var reference_meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/box-destruction-source.json"))
	check(("class_name CombatEffects\n" + FileAccess.get_file_as_string("res://tests/box_destruction_fixture.gd")).sha256_text() == reference_meta["source_sha256"], "paired box emitter is the exact frozen accepted source")
	var reference: Array = TRACE.run(root, LEGACY)
	var traces: Array = TRACE.run(root)
	var golden_matches: bool = true
	for i in range(traces.size()):
		var a: Dictionary = traces[i]
		var b: Dictionary = reference[i]
		golden_matches = golden_matches and b["fingerprint"] == baseline["cases"][i]["fingerprint"]
		check(a["fingerprint"] == b["fingerprint"] and a["quality"] == int(b["quality"]) and a["flashes"] == b["flashes"] and a["peak"] == int(b["peak"]) and a["recycled"] == b["recycled"] and is_equal_approx(a["next_random"], b["next_random"]), "accepted-source effect flight/scale/cap/lifetime/recycling/RNG case %d remains identical" % i)
	var cue := await audio_tests()
	QAReport.write("res://builds/qa/destruction-tests.json", {"checks": checks, "failures": failures, "fragment_triangles": 8, "previous_fragment_triangles": 12, "trace_cases": traces, "paired_reference_cases": reference, "golden_fingerprints_match_reference": golden_matches, "reference_source": reference_meta, "destruction_cue": cue, "scope": "Synthetic simulation/PCM/routing checks; no phone FPS or human listening acceptance."})
	print("DESTRUCTION_RESULT checks=", checks, " failures=", failures.size())
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

func audio_tests() -> Dictionary:
	var builder := SwarmAudio.new()
	seed(9127)
	var expected := randi()
	seed(9127)
	var clip: AudioStreamWAV = builder.destruction_crunch()
	check(randi() == expected, "original crunch synthesis never advances global/gameplay RNG")
	check(clip.data == builder.destruction_crunch().data, "original destruction PCM is deterministic")
	check(clip.format == AudioStreamWAV.FORMAT_16_BITS and not clip.stereo and clip.mix_rate == 22050 and clip.loop_mode == AudioStreamWAV.LOOP_DISABLED and clip.data.size() == 6174, "destruction cue retains original 140ms mono sixteen-bit duration")
	var peak: float = 0
	var energy: float = 0
	var dc: float = 0
	var max_step: float = 0
	var previous: float = 0
	for i in range(clip.data.size() / 2):
		var sample: float = clip.data.decode_s16(i * 2) / 32768.0
		peak = maxf(peak, absf(sample))
		energy += sample * sample
		dc += sample
		max_step = maxf(max_step, absf(sample - previous))
		previous = sample
	var count: int = clip.data.size() / 2
	var rms: float = sqrt(energy / count)
	check(peak > 0.1 and peak < 0.6 and rms > 0.02 and rms < 0.15 and absf(dc / count) < 0.01, "destruction PCM has bounded non-silent energy, headroom and low DC")
	check(clip.data.decode_s16(0) == 0 and clip.data.decode_s16(clip.data.size() - 2) == 0, "crunch has zero-ended attack/release")
	var playback := clip.instantiate_playback()
	playback.start()
	var finite := true
	for i in range(ceili(float(AudioServer.get_mix_rate()) * 0.20 / 1024.0)):
		var mixed: PackedVector2Array = playback.mix_audio(1.0, 1024)
		for sample in mixed:
			finite = finite and sample.is_finite() and absf(sample.x) <= 1 and absf(sample.y) <= 1
	check(finite and not playback.is_playing(), "one-shot destruction playback/resampling stays finite and terminates")
	playback.stop()
	playback = null
	check(clip.save_to_wav("res://builds/qa/destruction-cue.wav") == OK, "original crunch WAV exported for human listening review")
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(clip.data)
	var receipt := {"raw_pcm_sha256": digest.finish().hex_encode(), "duration_seconds": clip.get_length(), "sample_rate": clip.mix_rate, "mono": true, "peak": peak, "rms": rms, "dc_offset": dc / count, "largest_sample_step": max_step, "voices": 12, "minimum_interval_ms": 65, "scope": "Offline PCM/playback/routing; emulator audio disabled, human listening/mix unverified."}
	builder.free()
	var audio := SwarmAudio.new()
	root.add_child(audio)
	audio.set_process(false)
	check(audio.voices.size() == 12 and audio.sounds["kill"].data == clip.data, "existing kill ID is connected to original crunch without adding voices")
	audio.play("kill")
	check(audio.cursor == 1 and audio.voices[0].playing and audio.voices[0].bus == "SFX" and audio.voices[0].volume_db == -12 and audio.voices[0].stream == audio.sounds["kill"], "actual kill cue uses existing SFX voice/mix/pitch path")
	# Pin the cooldown fixture so slow test scheduling cannot expire the gate.
	audio.last_played["kill"] = Time.get_ticks_msec() + 60000
	for i in range(100):
		audio.play("kill")
	check(audio.cursor == 1, "existing 65ms kill gate rejects burst requests without a queue")
	var settings: Dictionary = SaveStore.defaults()["settings"]
	settings["sfx"] = 0.0
	audio.apply(settings)
	check(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(audio.voices[0].bus)) <= -79, "existing SFX mute attenuates destruction cue")
	settings["sfx"] = 0.65
	audio.apply(settings)
	audio.shutdown()
	await create_timer(0.20).timeout
	audio.queue_free()
	await process_frame
	clip = null
	var game: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.audio.set_process(false)
	game.save.path = "user://qa_destruction_feedback.json"
	game.save.data = SaveStore.defaults()
	game.start_run()
	while Engine.get_physics_frames() % 3 != 0:
		await physics_frame
	var foe: SwarmEnemy = game.combat.spawn(0, Vector3(3, 0, 0))
	var xp: int = foe.definition.xp
	game.combat._damage(foe, foe.hp)
	check(game.combat.kills == 1 and game.pickups.outstanding_xp() == xp and not foe.active, "actual damage/death retains exact kill and XP reward")
	check(game.audio.last_played.has("kill") and game.audio.voices[0].stream == game.audio.sounds["kill"] and game.audio.voices[0].playing, "real destruction callback dispatches new crunch through unchanged kill trigger")
	var fragments: int = 0
	for item in game.combat.effects.live:
		if item["kind"] == "shard" and item["mesh"].mesh == game.combat.effects.shard_mesh:
			fragments += 1
	check(fragments == 4, "real ordinary enemy death uses the original medium-quality four-fragment budget")
	game.audio.shutdown()
	await create_timer(0.20).timeout
	game.queue_free()
	await process_frame
	return receipt

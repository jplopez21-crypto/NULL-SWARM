extends RefCounted

# Synthetic accepted-source reference for effect caps, RNG, flight and recycling.
# Mesh topology is intentionally excluded; all effect state/poses are retained.
static func run(parent: Node) -> Array:
	var cases: Array = []
	for quality in range(3):
		for flashes in [false, true]:
			seed(1729 + quality * 10 + int(flashes))
			var fx := CombatEffects.new()
			parent.add_child(fx)
			fx.quality = quality
			fx.flashes = flashes
			var digest := HashingContext.new()
			digest.start(HashingContext.HASH_SHA256)
			var peak: int = 0
			for frame in range(180):
				var at := Vector3(2, 0.5, -3)
				if frame % 11 == 0:
					fx.destruction(at, Color("ff9274"), frame % 22 == 0)
				if frame % 13 == 0:
					fx.emit_fx("spark", at, at, Color("e5fff5"), 0.25)
				if frame % 17 == 0:
					fx.emit_fx("beam", at, at + Vector3(3, 0, -2), Color("80ffdb"), 0.12)
				if frame % 19 == 0:
					fx.emit_fx("dash", at, at + Vector3.RIGHT, Color("80ffdb"), 0.18)
				if frame % 23 == 0:
					fx.emit_fx("uplink", at, at, Color("ffe39b"), 3.0)
				if frame == 7:
					for i in range(180):
						fx.emit_fx("shard", at, at, Color("ff9274"), 0.22)
				fx.tick(0.0 if frame == 31 else 1.0 / 60.0)
				peak = maxi(peak, fx.live.size())
				var row: Array = [fx.live.size(), fx.pool.size()]
				for item in fx.live:
					var node: MeshInstance3D = item["mesh"]
					var color: Color = node.material_override.albedo_color
					var state: Array = [item["kind"], item["life"], item["duration"], item["size"],
						node.position.x, node.position.y, node.position.z, node.rotation.x, node.rotation.y, node.rotation.z,
						node.scale.x, node.scale.y, node.scale.z, item["velocity"].x, item["velocity"].y, item["velocity"].z,
						color.r, color.g, color.b, color.a, float(node.visible)]
					for i in range(1, state.size()):
						state[i] = snappedf(state[i], 0.000001)
					row.append(state)
				digest.update(JSON.stringify(row).to_utf8_buffer())
			fx.tick(100)
			cases.append({"quality": quality, "flashes": flashes, "frames": 180, "peak": peak,
				"recycled": fx.live.is_empty() and fx.pool.size() == 160,
				"fingerprint": digest.finish().hex_encode(), "next_random": snappedf(randf(), 0.000001)})
			parent.remove_child(fx)
			fx.free()
	return cases

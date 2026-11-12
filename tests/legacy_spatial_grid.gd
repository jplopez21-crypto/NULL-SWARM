extends SpatialGrid

# Frozen pre-fast-path query kernels for ordered parity and paired timing.
func query(point: Vector3, radius: float) -> Array:
	var result: Array = []
	var low := Vector2i(floori((point.x - radius) / CELL), floori((point.z - radius) / CELL))
	var high := Vector2i(floori((point.x + radius) / CELL), floori((point.z + radius) / CELL))
	for x in range(low.x, high.x + 1):
		for z in range(low.y, high.y + 1):
			for entity in cells.get(Vector2i(x, z), []):
				if entity.active and entity.position.distance_squared_to(point) <= radius * radius:
					result.append(entity)
	return result

func nearest(point: Vector3, radius: float, excluded: Array = []) -> Node3D:
	var found: Node3D
	var best: float = radius * radius
	var low := Vector2i(floori((point.x - radius) / CELL), floori((point.z - radius) / CELL))
	var high := Vector2i(floori((point.x + radius) / CELL), floori((point.z + radius) / CELL))
	for x in range(low.x, high.x + 1):
		for z in range(low.y, high.y + 1):
			for entity in cells.get(Vector2i(x, z), []):
				if not entity.active or (not excluded.is_empty() and excluded.has(entity.index)):
					continue
				var distance: float = entity.position.distance_squared_to(point)
				if distance < best:
					best = distance
					found = entity
	return found

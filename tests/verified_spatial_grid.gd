extends SpatialGrid

# Frozen query from verified code 738a047; use for paired timing of the fallback change.
func query(point: Vector3, radius: float) -> Array:
	var result: Array = []
	var radius_squared: float = radius * radius
	var low := Vector2i(floori((point.x - radius) / CELL), floori((point.z - radius) / CELL))
	var high := Vector2i(floori((point.x + radius) / CELL), floori((point.z + radius) / CELL))
	for x in range(low.x, high.x + 1):
		for z in range(low.y, high.y + 1):
			for entity in cells.get(Vector2i(x, z), []):
				if entity.active and entity.position.distance_squared_to(point) <= radius_squared:
					result.append(entity)
	return result


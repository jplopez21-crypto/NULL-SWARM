class_name SpatialGrid
extends RefCounted

const CELL: float = 4.0
var cells: Dictionary = {}

func rebuild(entities: Array) -> void:
	cells.clear()
	for entity in entities:
		if not entity.active:
			continue
		var key := Vector2i(floori(entity.position.x / CELL), floori(entity.position.z / CELL))
		if not cells.has(key):
			cells[key] = []
		cells[key].append(entity)

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

func nearest(point: Vector3, radius: float) -> Node3D:
	var found: Node3D
	var best: float = radius * radius
	for entity in query(point, radius):
		var distance: float = entity.position.distance_squared_to(point)
		if distance < best:
			best = distance
			found = entity
	return found

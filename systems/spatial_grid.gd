class_name SpatialGrid
extends RefCounted

const CELL: float = 4.0
const EMPTY_BUCKET: Array = []
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
	return query_into(point, radius, [])

func query_into(point: Vector3, radius: float, result: Array) -> Array:
	# Caller owns the scratch array. Finish the ordered snapshot before any hits;
	# nested allocating queries must never overwrite another attack's candidates.
	result.clear()
	var radius_squared: float = radius * radius
	var low := Vector2i(floori((point.x - radius) / CELL), floori((point.z - radius) / CELL))
	var high := Vector2i(floori((point.x + radius) / CELL), floori((point.z + radius) / CELL))
	for x in range(low.x, high.x + 1):
		for z in range(low.y, high.y + 1):
			for entity in cells.get(Vector2i(x, z), EMPTY_BUCKET):
				if entity.active and entity.position.distance_squared_to(point) <= radius_squared:
					result.append(entity)
	return result

func nearest(point: Vector3, radius: float, excluded: Array = []) -> Node3D:
	# Visit cells in query order to preserve deterministic equal-distance ties.
	# No candidate array or repeated distance calculation on this hot path.
	var found: Node3D
	var best: float = radius * radius
	var low := Vector2i(floori((point.x - radius) / CELL), floori((point.z - radius) / CELL))
	var high := Vector2i(floori((point.x + radius) / CELL), floori((point.z + radius) / CELL))
	for x in range(low.x, high.x + 1):
		for z in range(low.y, high.y + 1):
			var bucket: Variant = cells.get(Vector2i(x, z))
			if bucket == null:
				continue
			for entity in bucket:
				if not entity.active or (not excluded.is_empty() and excluded.has(entity.index)):
					continue
				var distance: float = entity.position.distance_squared_to(point)
				if distance < best:
					best = distance
					found = entity
	return found

func relocate(entity: Node3D, previous: Vector3) -> void:
	var old_key := Vector2i(floori(previous.x / CELL), floori(previous.z / CELL))
	var new_key := Vector2i(floori(entity.position.x / CELL), floori(entity.position.z / CELL))
	if old_key == new_key:
		return
	if cells.has(old_key):
		cells[old_key].erase(entity)
		if cells[old_key].is_empty():
			cells.erase(old_key)
	var bucket: Array = cells.get(new_key, [])
	var index: int = 0
	while index < bucket.size() and bucket[index].index < entity.index:
		index += 1
	bucket.insert(index, entity)
	cells[new_key] = bucket

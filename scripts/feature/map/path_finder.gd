class_name PathFinder
extends RefCounted

var _map_state: MapState


func initialize(map_state: MapState) -> void:
	_map_state = map_state


func is_adjacent(node_a_id: StringName, node_b_id: StringName) -> bool:
	var node_a := _map_state.get_node_by_id(node_a_id)
	if node_a == null:
		return false
	return node_a.connections.has(node_b_id)


func get_shortest_path(from_id: StringName, to_id: StringName) -> Array[StringName]:
	if from_id == to_id:
		return [from_id]

	var visited: Dictionary = {from_id: true}
	var parent: Dictionary = {}
	var queue: Array[StringName] = [from_id]
	var front := 0

	while front < queue.size():
		var current_id := queue[front]
		front += 1

		var current := _map_state.get_node_by_id(current_id)
		if current == null:
			continue

		for conn_id in current.connections:
			if conn_id == to_id:
				var path: Array[StringName] = []
				var trace_id := current_id
				while trace_id != from_id:
					path.append(trace_id)
					trace_id = parent.get(trace_id, from_id)
				path.append(from_id)
				path.reverse()
				path.append(to_id)
				return path

			if not visited.has(conn_id):
				visited[conn_id] = true
				parent[conn_id] = current_id
				queue.append(conn_id)

	return []


func get_reachable_nodes(from_id: StringName, max_distance: int = -1) -> Array[MapNodeData]:
	var visited: Dictionary = {from_id: true}
	var result: Array[MapNodeData] = []
	var queue: Array = [[from_id, 0]]
	var front := 0

	while front < queue.size():
		var item: Array = queue[front]
		front += 1
		var current_id: StringName = item[0]
		var dist: int = item[1]

		if max_distance >= 0 and dist > max_distance:
			continue

		var current := _map_state.get_node_by_id(current_id)
		if current != null and current_id != from_id:
			result.append(current)

		if max_distance < 0 or dist < max_distance:
			for neighbor in _map_state.get_neighbors(current_id):
				if not visited.has(neighbor.id):
					visited[neighbor.id] = true
					queue.append([neighbor.id, dist + 1])

	return result


func path_length(from_id: StringName, to_id: StringName) -> int:
	var path := get_shortest_path(from_id, to_id)
	if path.is_empty():
		return -1
	return path.size() - 1

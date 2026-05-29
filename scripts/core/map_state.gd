class_name MapState
extends RefCounted

var nodes: Dictionary = {}  # StringName id -> MapNodeData
var player_node_id: StringName
var previous_node_id: StringName
var current_chapter: int = 1


func initialize_from_graph(graph_nodes: Array[MapNodeData], start_id: StringName) -> void:
	nodes.clear()
	for node in graph_nodes:
		nodes[node.id] = node
	visit_node(start_id)


func get_player_node() -> MapNodeData:
	return nodes.get(player_node_id) as MapNodeData


func get_node_by_id(id: StringName) -> MapNodeData:
	return nodes.get(id) as MapNodeData


func get_neighbors(node_id: StringName) -> Array[MapNodeData]:
	var node := get_node_by_id(node_id)
	if node == null:
		return []
	var result: Array[MapNodeData] = []
	for conn_id in node.connections:
		var neighbor := get_node_by_id(conn_id)
		if neighbor != null:
			result.append(neighbor)
	return result


func reveal_node(node_id: StringName) -> void:
	var node := get_node_by_id(node_id)
	if node != null and node.visibility == GameEnums.MapNodeVisibility.UNEXPLORED:
		node.visibility = GameEnums.MapNodeVisibility.REVEALED


func visit_node(node_id: StringName) -> void:
	var node := get_node_by_id(node_id)
	if node != null:
		if player_node_id != node_id and player_node_id != &"":
			previous_node_id = player_node_id
		node.visibility = GameEnums.MapNodeVisibility.VISITED
		player_node_id = node_id
		_reveal_adjacent(node_id)


func retreat_to_previous_node() -> bool:
	if previous_node_id == &"":
		return false
	var current := get_player_node()
	if current != null and current.visibility == GameEnums.MapNodeVisibility.VISITED:
		current.visibility = GameEnums.MapNodeVisibility.REVEALED
	player_node_id = previous_node_id
	previous_node_id = &""
	return true


func clear_node(node_id: StringName) -> void:
	var node := get_node_by_id(node_id)
	if node != null:
		node.visibility = GameEnums.MapNodeVisibility.CLEARED
		if node.node_type != GameEnums.MapNodeType.BOSS and node.node_type != GameEnums.MapNodeType.START:
			node.node_type = GameEnums.MapNodeType.ROAD


func _reveal_adjacent(node_id: StringName) -> void:
	for neighbor in get_neighbors(node_id):
		if neighbor.visibility == GameEnums.MapNodeVisibility.UNEXPLORED:
			neighbor.visibility = GameEnums.MapNodeVisibility.REVEALED


func get_nodes_by_type(type: GameEnums.MapNodeType) -> Array[MapNodeData]:
	var result: Array[MapNodeData] = []
	for node in nodes.values():
		if node.node_type == type:
			result.append(node)
	return result


func shortest_path_length(from_id: StringName, to_id: StringName) -> int:
	if from_id == to_id:
		return 0
	var visited: Dictionary = {from_id: true}
	var queue: Array = [[from_id, 0]]
	var front := 0
	while front < queue.size():
		var current: Array = queue[front]
		front += 1
		var current_id: StringName = current[0]
		var dist: int = current[1]
		for neighbor in get_neighbors(current_id):
			if neighbor.id == to_id:
				return dist + 1
			if not visited.has(neighbor.id):
				visited[neighbor.id] = true
				queue.append([neighbor.id, dist + 1])
	return -1


func find_nearest_node_of_type(from_id: StringName, type: GameEnums.MapNodeType) -> MapNodeData:
	var visited: Dictionary = {from_id: true}
	var queue: Array = [from_id]
	var front := 0
	while front < queue.size():
		var current_id: StringName = queue[front]
		front += 1
		var current := get_node_by_id(current_id)
		if current.node_type == type:
			return current
		for neighbor in get_neighbors(current_id):
			if not visited.has(neighbor.id):
				visited[neighbor.id] = true
				queue.append(neighbor.id)
	return null

class_name MapGenerator
extends RefCounted

const VALIDATION_RETRY_LIMIT: int = 100

var _rng: RandomNumberGenerator
var _chapter: int = 1


func initialize(rng: RandomNumberGenerator = null) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()


func generate(chapter: int) -> Array[MapNodeData]:
	_chapter = chapter
	var layer_distribution: Array[int] = _pick_variant_and_get_layers()
	var special_slots := _get_special_slots()
	var random_pool := _get_random_pool()

	for attempt in range(VALIDATION_RETRY_LIMIT):
		var nodes := _build_nodes(layer_distribution, special_slots, random_pool.duplicate())
		var connections_ok := _build_connections(nodes, layer_distribution, special_slots)
		if connections_ok and _validate_graph(nodes):
			_assign_coordinates(nodes, layer_distribution)
			return nodes

	# Fallback: minimally connected tree
	return _build_fallback_tree(layer_distribution, special_slots, random_pool)


func _pick_variant_and_get_layers() -> Array[int]:
	var variants = [
		[5, 6, 4, 6, 5, 5, 3],   # Free Graph
		[6, 6, 5, 5, 4, 4, 4],   # Funnel Strangulation
		[5, 5, 5, 5, 5, 5, 4],   # Loop Maze
	]
	var idx := _rng.randi_range(0, variants.size() - 1)
	var raw: Array = variants[idx]
	var result: Array[int] = []
	for v in raw:
		result.append(v)
	return result


func _get_special_slots() -> Dictionary:
	# All Chapter 1 variants share these special node positions
	return {
		"L2_3": GameEnums.MapNodeType.BLACK_MARKET,
		"L3_2": GameEnums.MapNodeType.SAFE_HOUSE,
		"L3_3": GameEnums.MapNodeType.QUEST,
		"L5_2": GameEnums.MapNodeType.BLACK_MARKET,
		"L5_4": GameEnums.MapNodeType.SAFE_HOUSE,
	}


func _get_random_pool() -> Array[GameEnums.MapNodeType]:
	var pool: Array[GameEnums.MapNodeType] = []
	for i in range(8):  pool.append(GameEnums.MapNodeType.NORMAL_COMBAT)
	for i in range(4):  pool.append(GameEnums.MapNodeType.HARD_COMBAT)
	for i in range(8):  pool.append(GameEnums.MapNodeType.RANDOM_EVENT)
	for i in range(3):  pool.append(GameEnums.MapNodeType.RUINS)
	for i in range(6):  pool.append(GameEnums.MapNodeType.ROAD)
	return pool


func _build_nodes(layers: Array[int], special_slots: Dictionary, random_pool: Array[GameEnums.MapNodeType]) -> Array[MapNodeData]:
	var nodes: Array[MapNodeData] = []
	var shuffled_pool := random_pool.duplicate()
	# Fisher-Yates shuffle
	for i in range(shuffled_pool.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = shuffled_pool[i]
		shuffled_pool[i] = shuffled_pool[j]
		shuffled_pool[j] = tmp

	var pool_idx := 0
	var total_slots := 0
	for layer_size in layers:
		total_slots += layer_size

	# Create START node
	var start_node := MapNodeData.new()
	start_node.id = &"START"
	start_node.node_type = GameEnums.MapNodeType.START
	start_node.layer = 0
	start_node.slot_index = 0
	start_node.visibility = GameEnums.MapNodeVisibility.VISITED
	nodes.append(start_node)

	# Create layer nodes
	var slot_counter := 0
	for layer_idx in range(layers.size()):
		var layer_num := layer_idx + 1
		var layer_size := layers[layer_idx]
		for slot_idx in range(layer_size):
			var slot_name := "L%d_%d" % [layer_num, slot_idx + 1]
			var node := MapNodeData.new()
			node.id = StringName(slot_name)
			node.layer = layer_num
			node.slot_index = slot_idx + 1

			if special_slots.has(slot_name):
				node.node_type = special_slots[slot_name]
			else:
				if pool_idx < shuffled_pool.size():
					node.node_type = shuffled_pool[pool_idx]
					pool_idx += 1
				else:
					node.node_type = GameEnums.MapNodeType.ROAD

			nodes.append(node)
			slot_counter += 1

	# Create BOSS node
	var boss_node := MapNodeData.new()
	boss_node.id = &"BOSS"
	boss_node.node_type = GameEnums.MapNodeType.BOSS
	boss_node.layer = layers.size() + 1
	boss_node.slot_index = 0
	nodes.append(boss_node)

	return nodes


func _build_connections(nodes: Array[MapNodeData], _layers: Array[int], _special_slots: Dictionary) -> bool:
	var node_map := _index_nodes(nodes)

	# Connect START to all Layer 1 nodes
	for node in nodes:
		if node.layer == 1:
			_add_bidirectional(node_map, &"START", node.id)

	# Connect all Layer 7 nodes to BOSS (assuming 7 layers for Ch1)
	var last_layer := 0
	for node in nodes:
		last_layer = maxi(last_layer, node.layer)
	for node in nodes:
		if node.layer == last_layer:
			_add_bidirectional(node_map, node.id, &"BOSS")

	# Build random connections between adjacent layers and same layer
	var max_layer := last_layer
	for layer in range(1, max_layer):
		var current_layer_nodes := _get_nodes_in_layer(nodes, layer)
		var next_layer_nodes := _get_nodes_in_layer(nodes, layer + 1)

		# Ensure each node in current layer has at least one forward connection
		for node in current_layer_nodes:
			var has_forward := false
			for conn_id in node.connections:
				var conn := node_map.get(conn_id) as MapNodeData
				if conn != null and conn.layer > node.layer:
					has_forward = true
					break
			if not has_forward and next_layer_nodes.size() > 0:
				var target := next_layer_nodes[_rng.randi_range(0, next_layer_nodes.size() - 1)]
				_add_bidirectional(node_map, node.id, target.id)

		# Add some same-layer connections
		if current_layer_nodes.size() >= 2:
			var same_layer_count := mini(current_layer_nodes.size() / 2, 3)
			for _i in range(same_layer_count):
				var a := current_layer_nodes[_rng.randi_range(0, current_layer_nodes.size() - 1)]
				var b := current_layer_nodes[_rng.randi_range(0, current_layer_nodes.size() - 1)]
				if a.id != b.id:
					_add_bidirectional(node_map, a.id, b.id)

		# Add some cross-layer jumps (layer i to i+2)
		if layer + 2 <= max_layer:
			var jump_targets := _get_nodes_in_layer(nodes, layer + 2)
			if jump_targets.size() > 0 and current_layer_nodes.size() > 0:
				var source := current_layer_nodes[_rng.randi_range(0, current_layer_nodes.size() - 1)]
				var target := jump_targets[_rng.randi_range(0, jump_targets.size() - 1)]
				_add_bidirectional(node_map, source.id, target.id)

	return true


func _add_bidirectional(node_map: Dictionary, a: StringName, b: StringName) -> void:
	var node_a := node_map.get(a) as MapNodeData
	var node_b := node_map.get(b) as MapNodeData
	if node_a == null or node_b == null:
		return
	if not node_a.connections.has(b):
		node_a.connections.append(b)
	if not node_b.connections.has(a):
		node_b.connections.append(a)


func _index_nodes(nodes: Array[MapNodeData]) -> Dictionary:
	var result := {}
	for node in nodes:
		result[node.id] = node
	return result


func _get_nodes_in_layer(nodes: Array[MapNodeData], layer: int) -> Array[MapNodeData]:
	var result: Array[MapNodeData] = []
	for node in nodes:
		if node.layer == layer:
			result.append(node)
	return result


func _validate_graph(nodes: Array[MapNodeData]) -> bool:
	var node_map := _index_nodes(nodes)

	# Check START can reach BOSS
	var visited: Dictionary = {&"START": true}
	var queue: Array[StringName] = [&"START"]
	var front := 0
	var found_boss := false
	while front < queue.size():
		var current_id := queue[front]
		front += 1
		if current_id == &"BOSS":
			found_boss = true
			break
		var current := node_map.get(current_id) as MapNodeData
		if current == null:
			continue
		for conn_id in current.connections:
			if not visited.has(conn_id):
				visited[conn_id] = true
				queue.append(conn_id)

	if not found_boss:
		return false

	# Check dead-end ratio
	var dead_end_count := 0
	var intermediate_count := 0
	for node in nodes:
		if node.id == &"START" or node.id == &"BOSS":
			continue
		intermediate_count += 1
		if node.connections.size() == 1:
			dead_end_count += 1

	if intermediate_count > 0:
		var dead_ratio := float(dead_end_count) / intermediate_count
		if dead_ratio < 0.15 or dead_ratio > 0.30:
			return false

	return true


func _assign_coordinates(nodes: Array[MapNodeData], layers: Array[int]) -> void:
	var screen_left_margin := 80.0
	var horizontal_spacing := 140.0
	var top_margin := 60.0
	var available_height := 600.0  # Approximate for 720p

	for node in nodes:
		if node.id == &"START":
			node.position = Vector2(screen_left_margin - horizontal_spacing * 0.5, available_height * 0.5)
			continue
		if node.id == &"BOSS":
			node.position = Vector2(
				screen_left_margin + (layers.size()) * horizontal_spacing + horizontal_spacing * 0.5,
				available_height * 0.5
			)
			continue

		var x_base := screen_left_margin + (node.layer - 1) * horizontal_spacing
		var x_jitter := _rng.randf_range(-12.0, 12.0)

		var layer_nodes := _get_nodes_in_layer(nodes, node.layer)
		var slot_in_layer := -1
		for i in range(layer_nodes.size()):
			if layer_nodes[i].id == node.id:
				slot_in_layer = i
				break

		var y_uniform := 0.0
		if layer_nodes.size() > 0:
			y_uniform = top_margin + (float(slot_in_layer) / (layer_nodes.size() + 1)) * available_height
		var y_jitter := _rng.randf_range(-8.0, 8.0)

		node.position = Vector2(x_base + x_jitter, y_uniform + y_jitter)


func _build_fallback_tree(layers: Array[int], special_slots: Dictionary, random_pool: Array[GameEnums.MapNodeType]) -> Array[MapNodeData]:
	var nodes := _build_nodes(layers, special_slots, random_pool)
	var node_map := _index_nodes(nodes)
	var max_layer := 0
	for node in nodes:
		max_layer = maxi(max_layer, node.layer)

	# Minimal tree: connect each layer to the next in sequence
	for layer in range(1, max_layer):
		var current := _get_nodes_in_layer(nodes, layer)
		var nxt := _get_nodes_in_layer(nodes, layer + 1)
		if current.size() > 0 and nxt.size() > 0:
			_add_bidirectional(node_map, current[0].id, nxt[0].id)

	# Connect START and BOSS
	var layer1 := _get_nodes_in_layer(nodes, 1)
	if layer1.size() > 0:
		_add_bidirectional(node_map, &"START", layer1[0].id)
	var last_layer_nodes := _get_nodes_in_layer(nodes, max_layer)
	if last_layer_nodes.size() > 0:
		_add_bidirectional(node_map, last_layer_nodes[0].id, &"BOSS")

	_assign_coordinates(nodes, layers)
	return nodes

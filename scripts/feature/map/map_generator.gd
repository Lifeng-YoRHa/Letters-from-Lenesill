class_name MapGenerator
extends RefCounted

var _rng: RandomNumberGenerator
var _chapter: int = 1


func initialize(rng: RandomNumberGenerator = null) -> void:
	_rng = rng if rng != null else RandomNumberGenerator.new()


func generate(chapter: int) -> Array[MapNodeData]:
	_chapter = chapter
	var special_slots := _get_special_slots()
	var random_pool := _get_random_pool()
	var variant := _rng.randi_range(0, 2)
	match variant:
		0: return _build_chapter1_ver1(special_slots, random_pool)
		1: return _build_chapter1_ver2(special_slots, random_pool)
		2: return _build_chapter1_ver3(special_slots, random_pool)
	return _build_chapter1_ver1(special_slots, random_pool)


func _get_special_slots() -> Dictionary:
	# All Chapter 1 variants share these special node positions
	return {
		"L2_3": GameEnums.MapNodeType.BLACK_MARKET,
		"L3_2": GameEnums.MapNodeType.SAFE_HOUSE,
		"L3_3": GameEnums.MapNodeType.QUEST,
		"L5_2": GameEnums.MapNodeType.BLACK_MARKET,
		"L5_4": GameEnums.MapNodeType.SAFE_HOUSE,
	}


const EVENT_TYPES: Array[StringName] = [
	&"theft", &"robbery", &"hitchhike", &"corpse",
	&"locked_box", &"destroyed_camp", &"gambler",
	&"rogue_market", &"dying_embers",
]

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

	# Create START node
	var start_node := MapNodeData.new()
	start_node.id = &"START"
	start_node.node_type = GameEnums.MapNodeType.START
	start_node.layer = 0
	start_node.slot_index = 0
	start_node.visibility = GameEnums.MapNodeVisibility.VISITED
	nodes.append(start_node)

	# Create layer nodes
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
					if node.node_type == GameEnums.MapNodeType.RANDOM_EVENT:
						node.event_type = EVENT_TYPES[_rng.randi_range(0, EVENT_TYPES.size() - 1)]
					pool_idx += 1
				else:
					node.node_type = GameEnums.MapNodeType.ROAD

			nodes.append(node)

	# Create BOSS node
	var boss_node := MapNodeData.new()
	boss_node.id = &"BOSS"
	boss_node.node_type = GameEnums.MapNodeType.BOSS
	boss_node.layer = layers.size() + 1
	boss_node.slot_index = 0
	nodes.append(boss_node)

	return nodes


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


func _assign_coordinates(nodes: Array[MapNodeData], layers: Array[int]) -> void:
	var screen_left_margin := 140.0
	var horizontal_spacing := 220.0
	var top_margin := 20.0
	var available_height := 1260.0

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


# === Template Builders ===

func _build_chapter1_ver1(special_slots: Dictionary, random_pool: Array[GameEnums.MapNodeType]) -> Array[MapNodeData]:
	var layers: Array[int] = [5, 6, 4, 6, 5, 5, 3]
	var nodes := _build_nodes(layers, special_slots, random_pool)
	var node_map := _index_nodes(nodes)

	# Connections from design/gdd/detailed_map/Chapter1-Ver1.md
	_add_bidirectional(node_map, &"START", &"L1_1")
	_add_bidirectional(node_map, &"START", &"L1_3")
	_add_bidirectional(node_map, &"START", &"L1_5")
	_add_bidirectional(node_map, &"L1_1", &"L2_1")
	_add_bidirectional(node_map, &"L1_1", &"L2_2")
	_add_bidirectional(node_map, &"L1_2", &"L2_3")
	_add_bidirectional(node_map, &"L1_4", &"L1_5")
	_add_bidirectional(node_map, &"L1_5", &"L2_3")
	_add_bidirectional(node_map, &"L1_5", &"L2_5")
	_add_bidirectional(node_map, &"L2_1", &"L3_1")
	_add_bidirectional(node_map, &"L2_1", &"L4_6")
	_add_bidirectional(node_map, &"L2_3", &"L2_4")
	_add_bidirectional(node_map, &"L2_3", &"L3_1")
	_add_bidirectional(node_map, &"L2_4", &"L3_4")
	_add_bidirectional(node_map, &"L2_6", &"L3_4")
	_add_bidirectional(node_map, &"L3_1", &"L3_2")
	_add_bidirectional(node_map, &"L3_1", &"L4_3")
	_add_bidirectional(node_map, &"L3_2", &"L4_2")
	_add_bidirectional(node_map, &"L3_2", &"L4_4")
	_add_bidirectional(node_map, &"L3_3", &"L3_4")
	_add_bidirectional(node_map, &"L3_3", &"L4_3")
	_add_bidirectional(node_map, &"L4_1", &"L5_1")
	_add_bidirectional(node_map, &"L4_2", &"L5_1")
	_add_bidirectional(node_map, &"L4_4", &"L4_5")
	_add_bidirectional(node_map, &"L4_5", &"L5_5")
	_add_bidirectional(node_map, &"L4_6", &"L5_5")
	_add_bidirectional(node_map, &"L5_1", &"L6_2")
	_add_bidirectional(node_map, &"L5_2", &"L5_3")
	_add_bidirectional(node_map, &"L5_2", &"L6_3")
	_add_bidirectional(node_map, &"L5_3", &"L4_5")
	_add_bidirectional(node_map, &"L5_4", &"L5_5")
	_add_bidirectional(node_map, &"L5_4", &"L6_1")
	_add_bidirectional(node_map, &"L5_5", &"L4_6")
	_add_bidirectional(node_map, &"L6_1", &"L6_2")
	_add_bidirectional(node_map, &"L6_1", &"L7_2")
	_add_bidirectional(node_map, &"L6_2", &"L7_1")
	_add_bidirectional(node_map, &"L6_3", &"L6_4")
	_add_bidirectional(node_map, &"L6_3", &"L7_3")
	_add_bidirectional(node_map, &"L6_4", &"L7_2")
	_add_bidirectional(node_map, &"L6_5", &"L7_2")
	_add_bidirectional(node_map, &"L7_1", &"BOSS")
	_add_bidirectional(node_map, &"L7_3", &"BOSS")

	_assign_coordinates(nodes, layers)
	return nodes


func _build_chapter1_ver2(special_slots: Dictionary, random_pool: Array[GameEnums.MapNodeType]) -> Array[MapNodeData]:
	var layers: Array[int] = [5, 5, 5, 5, 5, 5, 4]
	var nodes := _build_nodes(layers, special_slots, random_pool)
	var node_map := _index_nodes(nodes)

	# Connections from design/gdd/detailed_map/Chapter1-Ver2.md
	_add_bidirectional(node_map, &"START", &"L1_1")
	_add_bidirectional(node_map, &"START", &"L1_2")
	_add_bidirectional(node_map, &"START", &"L1_3")
	_add_bidirectional(node_map, &"L1_1", &"L2_1")
	_add_bidirectional(node_map, &"L1_2", &"L2_1")
	_add_bidirectional(node_map, &"L1_2", &"L2_2")
	_add_bidirectional(node_map, &"L1_3", &"L2_2")
	_add_bidirectional(node_map, &"L1_3", &"L2_3")
	_add_bidirectional(node_map, &"L1_4", &"L2_4")
	_add_bidirectional(node_map, &"L1_4", &"L3_2")
	_add_bidirectional(node_map, &"L1_5", &"L2_4")
	_add_bidirectional(node_map, &"L1_5", &"L2_5")
	_add_bidirectional(node_map, &"L2_1", &"L3_1")
	_add_bidirectional(node_map, &"L2_2", &"L3_2")
	_add_bidirectional(node_map, &"L2_3", &"L3_3")
	_add_bidirectional(node_map, &"L2_3", &"L3_5")
	_add_bidirectional(node_map, &"L2_4", &"L2_5")
	_add_bidirectional(node_map, &"L2_4", &"L3_4")
	_add_bidirectional(node_map, &"L2_5", &"L3_5")
	_add_bidirectional(node_map, &"L3_1", &"L4_1")
	_add_bidirectional(node_map, &"L3_2", &"L4_2")
	_add_bidirectional(node_map, &"L3_2", &"L5_2")
	_add_bidirectional(node_map, &"L3_3", &"L4_3")
	_add_bidirectional(node_map, &"L3_4", &"L4_4")
	_add_bidirectional(node_map, &"L3_5", &"L4_5")
	_add_bidirectional(node_map, &"L4_1", &"L5_1")
	_add_bidirectional(node_map, &"L4_2", &"L4_3")
	_add_bidirectional(node_map, &"L4_2", &"L5_2")
	_add_bidirectional(node_map, &"L4_2", &"L6_2")
	_add_bidirectional(node_map, &"L4_3", &"L4_4")
	_add_bidirectional(node_map, &"L4_3", &"L5_3")
	_add_bidirectional(node_map, &"L4_4", &"L5_4")
	_add_bidirectional(node_map, &"L4_4", &"L6_4")
	_add_bidirectional(node_map, &"L4_5", &"L5_5")
	_add_bidirectional(node_map, &"L5_1", &"L6_1")
	_add_bidirectional(node_map, &"L5_2", &"L6_2")
	_add_bidirectional(node_map, &"L5_3", &"L6_3")
	_add_bidirectional(node_map, &"L5_4", &"L6_4")
	_add_bidirectional(node_map, &"L5_5", &"L6_5")
	_add_bidirectional(node_map, &"L6_1", &"L7_1")
	_add_bidirectional(node_map, &"L6_2", &"L7_2")
	_add_bidirectional(node_map, &"L6_3", &"L7_3")
	_add_bidirectional(node_map, &"L6_4", &"L7_4")
	_add_bidirectional(node_map, &"L6_5", &"L7_2")
	_add_bidirectional(node_map, &"L7_1", &"BOSS")
	_add_bidirectional(node_map, &"L7_3", &"BOSS")

	_assign_coordinates(nodes, layers)
	return nodes


func _build_chapter1_ver3(special_slots: Dictionary, random_pool: Array[GameEnums.MapNodeType]) -> Array[MapNodeData]:
	var layers: Array[int] = [6, 6, 5, 5, 4, 4, 4]
	var nodes := _build_nodes(layers, special_slots, random_pool)
	var node_map := _index_nodes(nodes)

	# Connections from design/gdd/detailed_map/Chapter1-Ver3.md
	_add_bidirectional(node_map, &"START", &"L1_1")
	_add_bidirectional(node_map, &"START", &"L1_2")
	_add_bidirectional(node_map, &"START", &"L1_3")
	_add_bidirectional(node_map, &"START", &"L1_5")
	_add_bidirectional(node_map, &"L1_1", &"L2_1")
	_add_bidirectional(node_map, &"L1_2", &"L2_1")
	_add_bidirectional(node_map, &"L1_3", &"L2_2")
	_add_bidirectional(node_map, &"L1_3", &"L1_4")
	_add_bidirectional(node_map, &"L1_5", &"L2_5")
	_add_bidirectional(node_map, &"L1_5", &"L1_6")
	_add_bidirectional(node_map, &"L1_5", &"L2_6")
	_add_bidirectional(node_map, &"L2_1", &"L3_1")
	_add_bidirectional(node_map, &"L2_2", &"L2_3")
	_add_bidirectional(node_map, &"L2_2", &"L3_2")
	_add_bidirectional(node_map, &"L2_3", &"L3_2")
	_add_bidirectional(node_map, &"L2_3", &"L3_3")
	_add_bidirectional(node_map, &"L2_3", &"L2_4")
	_add_bidirectional(node_map, &"L2_5", &"L3_5")
	_add_bidirectional(node_map, &"L2_5", &"L2_6")
	_add_bidirectional(node_map, &"L2_6", &"L3_4")
	_add_bidirectional(node_map, &"L3_1", &"L4_1")
	_add_bidirectional(node_map, &"L3_2", &"L4_2")
	_add_bidirectional(node_map, &"L3_3", &"L4_3")
	_add_bidirectional(node_map, &"L3_5", &"L4_3")
	_add_bidirectional(node_map, &"L3_5", &"L4_4")
	_add_bidirectional(node_map, &"L3_5", &"L4_5")
	_add_bidirectional(node_map, &"L4_1", &"L4_2")
	_add_bidirectional(node_map, &"L4_2", &"L4_3")
	_add_bidirectional(node_map, &"L4_3", &"L4_4")
	_add_bidirectional(node_map, &"L4_4", &"L4_5")
	_add_bidirectional(node_map, &"L4_5", &"L5_1")
	_add_bidirectional(node_map, &"L4_5", &"L5_2")
	_add_bidirectional(node_map, &"L5_1", &"L5_2")
	_add_bidirectional(node_map, &"L5_1", &"L6_1")
	_add_bidirectional(node_map, &"L5_2", &"L5_3")
	_add_bidirectional(node_map, &"L5_2", &"L6_2")
	_add_bidirectional(node_map, &"L5_3", &"L5_4")
	_add_bidirectional(node_map, &"L5_3", &"L6_3")
	_add_bidirectional(node_map, &"L5_4", &"L6_4")
	_add_bidirectional(node_map, &"L6_1", &"L7_1")
	_add_bidirectional(node_map, &"L6_2", &"L7_2")
	_add_bidirectional(node_map, &"L6_3", &"L7_3")
	_add_bidirectional(node_map, &"L6_4", &"L7_4")
	_add_bidirectional(node_map, &"L7_1", &"BOSS")
	_add_bidirectional(node_map, &"L7_3", &"BOSS")

	_assign_coordinates(nodes, layers)
	return nodes

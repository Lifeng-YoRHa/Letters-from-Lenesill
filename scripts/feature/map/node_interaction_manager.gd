class_name NodeInteractionManager
extends RefCounted

signal combat_triggered(node_id: StringName, enemy_type: GameEnums.EnemyType)
signal boss_combat_triggered(node_id: StringName, boss_data: EnemyData)
signal shop_opened(node_id: StringName)
signal safe_house_opened(node_id: StringName)
signal event_triggered(node_id: StringName, event_type: StringName)
signal ruins_searched(node_id: StringName, search_count: int)
signal quest_triggered(node_id: StringName, quest_state: int)
signal no_interaction(node_id: StringName)

var _map_state: MapState
var _node_manager: NodeManager
var _ruins_search_counters: Dictionary = {}  # node_id -> int


func initialize(map_state: MapState, node_manager: NodeManager) -> void:
	_map_state = map_state
	_node_manager = node_manager


func process_node_arrival(node_id: StringName) -> void:
	var node := _map_state.get_node_by_id(node_id)
	if node == null:
		return

	match node.node_type:
		GameEnums.MapNodeType.NORMAL_COMBAT:
			combat_triggered.emit(node_id, GameEnums.EnemyType.NORMAL)

		GameEnums.MapNodeType.HARD_COMBAT:
			combat_triggered.emit(node_id, GameEnums.EnemyType.HARD)

		GameEnums.MapNodeType.BOSS:
			boss_combat_triggered.emit(node_id, null)

		GameEnums.MapNodeType.BLACK_MARKET:
			shop_opened.emit(node_id)

		GameEnums.MapNodeType.SAFE_HOUSE:
			safe_house_opened.emit(node_id)

		GameEnums.MapNodeType.RANDOM_EVENT:
			event_triggered.emit(node_id, &"random")

		GameEnums.MapNodeType.RUINS:
			var count: int = _ruins_search_counters.get(node_id, 0)
			ruins_searched.emit(node_id, count)

		GameEnums.MapNodeType.QUEST:
			quest_triggered.emit(node_id, 0)

		GameEnums.MapNodeType.ROAD, \
		GameEnums.MapNodeType.START:
			no_interaction.emit(node_id)


func record_ruins_search(node_id: StringName) -> void:
	var count: int = _ruins_search_counters.get(node_id, 0)
	_ruins_search_counters[node_id] = count + 1


func mark_node_cleared(node_id: StringName) -> void:
	_map_state.clear_node(node_id)


func get_node_interaction_type(node_id: StringName) -> GameEnums.MapNodeType:
	var node := _map_state.get_node_by_id(node_id)
	if node == null:
		return GameEnums.MapNodeType.ROAD
	return node.node_type


func is_node_interactable(node_id: StringName) -> bool:
	var node := _map_state.get_node_by_id(node_id)
	if node == null:
		return false
	if node.visibility == GameEnums.MapNodeVisibility.CLEARED:
		return false
	return node.node_type != GameEnums.MapNodeType.ROAD \
		and node.node_type != GameEnums.MapNodeType.START

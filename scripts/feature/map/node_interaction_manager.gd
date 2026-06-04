class_name NodeInteractionManager
extends RefCounted

signal combat_triggered(node_id: StringName, enemy_type: GameEnums.EnemyType)
signal boss_combat_triggered(node_id: StringName, boss_data: EnemyData)
signal shop_opened(node_id: StringName)
signal safe_house_opened(node_id: StringName)
signal event_triggered(node_id: StringName, event_type: StringName)
signal ruins_entered(node_id: StringName, search_count: int, stamina_cost: int)
signal ruins_searched(node_id: StringName, search_count: int)
signal quest_triggered(node_id: StringName, quest_state: int)
signal no_interaction(node_id: StringName)

var _map_state: MapState
var _node_manager: NodeManager
var _ruins_search_counters: Dictionary = {}  # node_id -> int
var _safe_house_states: Dictionary = {}  # node_id -> SafeHouseState
var _rng: RandomNumberGenerator


func initialize(map_state: MapState, node_manager: NodeManager, rng: RandomNumberGenerator = null) -> void:
	_map_state = map_state
	_node_manager = node_manager
	_rng = rng if rng != null else RandomNumberGenerator.new()


func process_node_arrival(node_id: StringName) -> void:
	var node := _map_state.get_node_by_id(node_id)
	if node == null:
		return
	if node.visibility == GameEnums.MapNodeVisibility.CLEARED:
		no_interaction.emit(node_id)
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
			var count: int = _ruins_search_counters.get(node_id, 0) as int
			var stamina_cost := count + 1
			ruins_entered.emit(node_id, count, stamina_cost)

		GameEnums.MapNodeType.QUEST:
			quest_triggered.emit(node_id, 0)

		GameEnums.MapNodeType.ROAD, \
		GameEnums.MapNodeType.START:
			no_interaction.emit(node_id)


func convert_node_to_road(node_id: StringName) -> void:
	var node := _map_state.get_node_by_id(node_id)
	if node == null:
		return
	node.node_type = GameEnums.MapNodeType.ROAD


func record_ruins_search(node_id: StringName) -> int:
	var count: int = _ruins_search_counters.get(node_id, 0) as int
	_ruins_search_counters[node_id] = count + 1
	return count + 1


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


func get_or_create_safe_house_state(node_id: StringName, chapter: int, scholar_stage: int) -> SafeHouseState:
	var existing: SafeHouseState = _safe_house_states.get(node_id) as SafeHouseState
	if existing != null:
		return existing
	var state := SafeHouseState.new()
	_generate_safe_house_content(state, chapter, scholar_stage)
	_safe_house_states[node_id] = state
	return state


func reset_safe_houses() -> void:
	_safe_house_states.clear()


func _generate_safe_house_content(state: SafeHouseState, chapter: int, scholar_stage: int) -> void:
	var scattered_count := 1
	var fridge_count := 2
	var piggy_bank_bonus := 0
	var anvil_uses := 1

	if scholar_stage >= 0:
		scattered_count += 1
	if scholar_stage >= 1:
		fridge_count += 1
	if scholar_stage >= 2:
		piggy_bank_bonus += 1
	if scholar_stage >= 3:
		anvil_uses += 1
	if scholar_stage >= 4:
		scattered_count += 1

	for i in range(fridge_count):
		var drink := ItemData.new()
		drink.id = &"energy_drink"
		drink.display_name = "能量饮料"
		drink.item_type = GameEnums.ItemType.CONSUMABLE
		drink.width = 1
		drink.height = 1
		state.fridge_items.append(drink)

	for i in range(scattered_count):
		var item := _roll_scattered_item()
		if item != null:
			state.scattered_items.append(item)

	var base_gold_pools := {
		1: [6, 7, 8, 9, 10],
		2: [8, 9, 10, 11, 12],
		3: [10, 11, 12, 13, 14],
		4: [12, 13, 14, 15, 16],
		5: [14, 15, 16, 17, 18],
	}
	var pool: Array = base_gold_pools.get(chapter, [6, 7, 8, 9, 10]) as Array
	state.piggy_bank_gold = pool[_rng.randi_range(0, pool.size() - 1)] + piggy_bank_bonus
	state.anvil_uses_remaining = anvil_uses


func _roll_scattered_item() -> ItemData:
	var roll := _rng.randf()
	var item := ItemData.new()
	item.item_type = GameEnums.ItemType.CONSUMABLE
	item.width = 1
	item.height = 1

	if roll < 0.21:
		item.id = &"whetstone"
		item.display_name = "磨刀石"
	elif roll < 0.37:
		item.id = &"stone"
		item.display_name = "石块"
	elif roll < 0.69:
		item.id = &"energy_drink"
		item.display_name = "能量饮料"
	elif roll < 0.84:
		item.id = &"flashlight"
		item.display_name = "手电筒"
		item.width = 1
		item.height = 2
	elif roll < 0.96:
		item.id = &"torch"
		item.display_name = "火把"
		item.width = 1
		item.height = 2
	else:
		item.id = &"safe_house_key"
		item.display_name = "安全屋房卡"

	return item

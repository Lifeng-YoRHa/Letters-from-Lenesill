class_name QuestManager
extends RefCounted

signal quest_accepted(chapter: int, quest_node_id: StringName)
signal quest_completed(chapter: int, reward_choice: Array)
signal lost_letter_spawned(location_node_id: StringName, location_type: StringName)
signal survivors_letter_obtained(count: int)

enum QuestState {
	INACTIVE,
	ACCEPTED,
	LETTER_FOUND,
	COMPLETED,
}

var _current_chapter: int = 1
var _quest_state: QuestState = QuestState.INACTIVE
var _quest_node_id: StringName = &""
var _lost_letter_location_id: StringName = &""
var _lost_letter_location_type: StringName = &""
var _has_lost_letter: bool = false
var _survivors_letter_count: int = 0
var _completed_quests: Array[int] = []

var _rng: RandomNumberGenerator
var _map_state: MapState
var _backpack_manager: BackpackManager
var _survivor_notes: SurvivorNotes
var _relic_handler: RelicHandler


func initialize(rng: RandomNumberGenerator, map_state: MapState, backpack_manager: BackpackManager, survivor_notes: SurvivorNotes, relic_handler: RelicHandler = null) -> void:
	_rng = rng
	_map_state = map_state
	_backpack_manager = backpack_manager
	_survivor_notes = survivor_notes
	_relic_handler = relic_handler


func start_chapter_quest(chapter: int, quest_node_id: StringName) -> void:
	_current_chapter = chapter
	_quest_node_id = quest_node_id
	_quest_state = QuestState.INACTIVE
	_has_lost_letter = false
	_lost_letter_location_id = &""


func accept_quest() -> void:
	if _quest_state != QuestState.INACTIVE:
		return
	_quest_state = QuestState.ACCEPTED
	quest_accepted.emit(_current_chapter, _quest_node_id)
	_spawn_lost_letter()


func _spawn_lost_letter() -> void:
	var roll := _rng.randf()
	var location_type: StringName
	var candidates: Array[MapNodeData] = []

	if roll < 0.70:
		location_type = &"hard_combat"
		candidates = _map_state.get_nodes_by_type(GameEnums.MapNodeType.HARD_COMBAT)
	elif roll < 0.85:
		location_type = &"black_market"
		candidates = _map_state.get_nodes_by_type(GameEnums.MapNodeType.BLACK_MARKET)
	elif roll < 0.95:
		location_type = &"safe_house"
		candidates = _map_state.get_nodes_by_type(GameEnums.MapNodeType.SAFE_HOUSE)
	else:
		location_type = &"normal_combat"
		candidates = _map_state.get_nodes_by_type(GameEnums.MapNodeType.NORMAL_COMBAT)

	if candidates.is_empty():
		# Fallback to any combat node
		candidates = _map_state.get_nodes_by_type(GameEnums.MapNodeType.NORMAL_COMBAT)
		candidates.append_array(_map_state.get_nodes_by_type(GameEnums.MapNodeType.HARD_COMBAT))

	if candidates.is_empty():
		return

	var chosen := candidates[_rng.randi_range(0, candidates.size() - 1)]
	_lost_letter_location_id = chosen.id
	_lost_letter_location_type = location_type
	lost_letter_spawned.emit(chosen.id, location_type)


func on_combat_victory(node_id: StringName) -> void:
	if _quest_state != QuestState.ACCEPTED:
		return
	if node_id == _lost_letter_location_id and (_lost_letter_location_type == &"normal_combat" or _lost_letter_location_type == &"hard_combat"):
		_grant_lost_letter()


func on_black_market_entered(node_id: StringName) -> void:
	if _quest_state != QuestState.ACCEPTED:
		return
	if node_id == _lost_letter_location_id and _lost_letter_location_type == &"black_market":
		# Lost Letter appears as 6th shop slot; purchase handled by ShopManager
		pass


func on_safe_house_entered(node_id: StringName) -> void:
	if _quest_state != QuestState.ACCEPTED:
		return
	if node_id == _lost_letter_location_id and _lost_letter_location_type == &"safe_house":
		_grant_lost_letter()


func purchase_lost_letter_from_shop() -> void:
	if _quest_state != QuestState.ACCEPTED:
		return
	_grant_lost_letter()


func _grant_lost_letter() -> void:
	var letter := ItemData.new()
	letter.id = &"lost_letter"
	letter.display_name = "Lost Letter"
	letter.item_type = GameEnums.ItemType.CONSUMABLE
	letter.width = 1
	letter.height = 1
	if _backpack_manager.add_item(letter):
		_has_lost_letter = true
		_quest_state = QuestState.LETTER_FOUND


func can_complete_quest() -> bool:
	if _quest_state != QuestState.LETTER_FOUND:
		return false
	return _has_lost_letter


func complete_quest(primary_reward: StringName, secondary_reward: StringName) -> Dictionary:
	if not can_complete_quest():
		return {"error": true}

	_quest_state = QuestState.COMPLETED
	_completed_quests.append(_current_chapter)

	# Remove Lost Letter from inventory
	for item in _backpack_manager.get_total_items():
		if item.id == &"lost_letter":
			_backpack_manager.remove_item(item)
			break

	# Grant Survivor's Letter
	var s_letter := ItemData.new()
	s_letter.id = &"survivors_letter"
	s_letter.display_name = "Survivor's Letter"
	s_letter.item_type = GameEnums.ItemType.CONSUMABLE
	s_letter.width = 1
	s_letter.height = 1
	_backpack_manager.add_item(s_letter)
	_survivors_letter_count += 1
	survivors_letter_obtained.emit(_survivors_letter_count)

	# Grant chosen rewards
	var rewards := _grant_rewards(primary_reward, secondary_reward)
	quest_completed.emit(_current_chapter, rewards)

	# Update Survivor Notes (Messenger entry)
	if _survivor_notes != null:
		_survivor_notes.add_progress(&"messenger", 1)

	return {"completed": true, "rewards": rewards}


func _grant_rewards(primary: StringName, secondary: StringName) -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	for choice in [primary, secondary]:
		match choice:
			&"weapon":
				rewards.append({"type": "weapon", "data": null})  # Placeholder
			&"backpack":
				rewards.append({"type": "backpack", "data": null})
			&"relic":
				var relic_count := 1 if _current_chapter <= 2 else 2
				rewards.append({"type": "relic", "count": relic_count})
			&"consumable":
				var counts := {1: 4, 2: 6, 3: 9, 4: 11}
				var count: int = counts.get(_current_chapter, 4)
				rewards.append({"type": "consumable", "count": count})
			&"gold":
				var gold_amounts := {1: 22, 2: 33, 3: 44, 4: 55}
				var gold: int = gold_amounts.get(_current_chapter, 22)
				if _relic_handler != null and _relic_handler.has_relic(&"torn_photo"):
					gold += 5
				_backpack_manager.add_gold(gold)
				rewards.append({"type": "gold", "amount": gold})
	return rewards


func get_quest_state() -> QuestState:
	return _quest_state


func get_survivors_letter_count() -> int:
	return _survivors_letter_count


func has_all_letters() -> bool:
	return _survivors_letter_count >= 4


func get_lost_letter_location() -> StringName:
	return _lost_letter_location_id


func on_chapter_transition() -> void:
	# Remove any Lost Letter from inventory on chapter transition
	for item in _backpack_manager.get_total_items():
		if item.id == &"lost_letter":
			_backpack_manager.remove_item(item)
			break
	_quest_state = QuestState.INACTIVE
	_has_lost_letter = false
	_lost_letter_location_id = &""

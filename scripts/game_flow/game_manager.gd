class_name GameManager
extends Node

enum GameState {
	MAIN_MENU,
	MAP_EXPLORATION,
	COMBAT,
	SHOP,
	EVENT,
	SAFE_HOUSE,
	CHAPTER_TRANSITION,
	ENDING,
}

signal state_changed(new_state: int, old_state: int)
signal chapter_started(chapter: int)
signal adventure_started()
signal adventure_ended(ending_type: StringName)
signal combat_prepared(combat_manager: CombatManager)
signal loot_generated(gold: int, items: Array[ItemData])
signal player_died
signal safe_house_prepared(node_id: StringName)
signal event_presented(title: String, description: String, choices: Array)
signal event_result_presented(title: String, description: String)
signal password_box_opened(item: ItemData, stamina_current: int, stamina_max: int)
signal password_box_hint(hint_text: String)
signal password_box_reward_granted(reward_desc: String)
signal stamina_changed(current_stamina: int, max_stamina: int)


# === Public references (for UI layer access) ===
var rng: RandomNumberGenerator
var map_generator: MapGenerator
var map_state: MapState
var path_finder: PathFinder
var node_manager: NodeManager
var node_interaction_manager: NodeInteractionManager
var backpack_manager: BackpackManager
var relic_handler: RelicHandler
var shop_manager: ShopManager
var event_manager: EventManager
var quest_manager: QuestManager
var survivor_notes: SurvivorNotes
var save_load_manager: SaveLoadManager
var ending_manager: EndingManager

# === Adventure runtime state ===
var current_state: int = GameState.MAIN_MENU
var current_chapter: int = 1
var current_combat_manager: CombatManager = null
var current_combat_node_id: StringName = &""
var current_interaction_node_id: StringName = &""
var current_stamina: Stamina
var non_road_nodes_visited: int = 0

var _current_enemy_type: GameEnums.EnemyType = GameEnums.EnemyType.NORMAL
var _current_event_type: StringName = &""
var _current_password_box_item: ItemData = null
var _last_gold_count: int = 0

const EVENT_TITLES: Dictionary = {
	&"theft":         "盗窃",
	&"robbery":       "抢劫",
	&"hitchhike":     "搭车",
	&"corpse":        "尸体",
	&"locked_box":    "密码箱",
	&"destroyed_camp":"被摧毁的营地",
	&"gambler":       "赌徒",
	&"rogue_market":  "黑市",
	&"dying_embers":  "余烬",
}


func _ready() -> void:
	_initialize_systems()
	_connect_signals()


func _initialize_systems() -> void:
	rng = RandomNumberGenerator.new()

	# Meta progression
	survivor_notes = SurvivorNotes.new()
	survivor_notes.initialize()

	# Save/Load
	save_load_manager = SaveLoadManager.new()

	# Map system
	map_generator = MapGenerator.new()
	map_generator.initialize(rng)
	map_state = MapState.new()
	path_finder = PathFinder.new()

	# Backpack & Relics
	backpack_manager = BackpackManager.new()
	backpack_manager.initialize()
	relic_handler = RelicHandler.new()
	relic_handler.initialize()

	# Node traversal & interaction
	node_manager = NodeManager.new()
	node_interaction_manager = NodeInteractionManager.new()

	# Events, Quests, Shop
	event_manager = EventManager.new()
	event_manager.initialize(rng, backpack_manager, relic_handler)
	quest_manager = QuestManager.new()
	quest_manager.initialize(rng, map_state, backpack_manager, survivor_notes, relic_handler)
	shop_manager = ShopManager.new()
	shop_manager.initialize(rng, relic_handler, backpack_manager)

	# Track gold changes for survivor notes
	_last_gold_count = backpack_manager.gold_count
	backpack_manager.gold_changed.connect(_on_gold_changed)

	# Ending
	ending_manager = EndingManager.new()
	ending_manager.initialize(quest_manager, survivor_notes)


func _connect_signals() -> void:
	# Node traversal
	node_manager.player_moved.connect(_on_player_moved)
	node_manager.node_visited.connect(_on_node_visited)
	node_manager.node_cleared.connect(_on_node_cleared)

	# Node interaction routing
	node_interaction_manager.combat_triggered.connect(_on_combat_triggered)
	node_interaction_manager.boss_combat_triggered.connect(_on_boss_combat_triggered)
	node_interaction_manager.shop_opened.connect(_on_shop_opened)
	node_interaction_manager.safe_house_opened.connect(_on_safe_house_opened)
	node_interaction_manager.event_triggered.connect(_on_event_triggered)
	node_interaction_manager.ruins_searched.connect(_on_ruins_searched)
	node_interaction_manager.quest_triggered.connect(_on_quest_triggered)

	# Event outcomes
	event_manager.teleport_requested.connect(_on_teleport_requested)
	event_manager.combat_triggered.connect(_on_event_combat_triggered)
	event_manager.stamina_changed.connect(_on_event_stamina_changed)
	# TODO: connect event_manager.locked_box_granted for UI notification

	# Ending
	ending_manager.false_ending_triggered.connect(_on_false_ending)
	ending_manager.true_ending_triggered.connect(_on_true_ending)
	ending_manager.run_completed.connect(_on_run_completed)


# === Public API ===

func start_new_adventure() -> void:
	current_chapter = 1
	non_road_nodes_visited = 0
	backpack_manager.reset()
	node_interaction_manager.reset_safe_houses()
	_setup_chapter(current_chapter)
	adventure_started.emit()
	var starting_gold_bonus := survivor_notes.get_starting_gold_bonus()
	if starting_gold_bonus > 0:
		backpack_manager.add_gold(starting_gold_bonus)
	_last_gold_count = backpack_manager.gold_count
	_change_state(GameState.MAP_EXPLORATION)


func load_adventure(slot_index: int) -> bool:
	var slot := save_load_manager.load_slot(slot_index)
	if slot == null:
		print("LOAD FAIL: slot is null")
		return false

	print("LOAD: slot loaded, adventure_layer=null? ", slot.adventure_layer == null, " meta_layer=null? ", slot.meta_layer == null)

	if slot.meta_layer != null:
		_restore_meta_state(slot.meta_layer)

	if slot.adventure_layer != null:
		_restore_adventure_state(slot.adventure_layer)
	else:
		print("LOAD WARN: adventure_layer is null, skipping state restore")

	adventure_started.emit()
	_last_gold_count = backpack_manager.gold_count

	if slot.adventure_layer != null and not slot.adventure_layer.combat_snapshot.is_empty():
		_restore_combat_from_snapshot(slot.adventure_layer.combat_snapshot)
		_change_state(GameState.COMBAT)
	else:
		_change_state(GameState.MAP_EXPLORATION)

	return true


func save_adventure(slot_index: int) -> bool:
	var adventure_state := _build_adventure_state()
	var meta_state := _build_meta_state()
	return save_load_manager.save_slot(slot_index, adventure_state, meta_state)


func _build_adventure_state() -> AdventureStateResource:
	var state := AdventureStateResource.new()
	state.chapter = current_chapter
	state.player_node_id = map_state.player_node_id
	state.previous_node_id = map_state.previous_node_id

	var node_array: Array[MapNodeData] = []
	for n in map_state.nodes.values():
		node_array.append(n as MapNodeData)
	state.nodes = node_array

	if current_combat_manager != null and current_combat_manager.combat_state != null:
		var cs := current_combat_manager.combat_state
		state.combat_snapshot = {
			"round_number": cs.round_number,
			"enemy_current_hp": cs.enemy_current_hp,
			"active_debuffs": cs.active_debuffs,
			"adrenaline_needle_used": not relic_handler._adrenaline_needle_available,
			"boss_emergency_heal_used": cs.boss_emergency_heal_used,
			"enemy_type": cs.encounter_type,
			"current_combat_node_id": current_combat_node_id,
		}
		state.boss_hp = cs.enemy_current_hp
		state.boss_emergency_heal_used = cs.boss_emergency_heal_used
	else:
		state.combat_snapshot = {}
		state.boss_hp = 0
		state.boss_emergency_heal_used = false

	state.stamina_current = current_stamina.current_stamina
	state.stamina_max = current_stamina.max_stamina
	state.gold = backpack_manager.gold_count
	state.backpack_type = backpack_manager.current_backpack_type
	state.backpack_items = _serialize_backpack_items()
	state.pocket_items = _serialize_pocket_items()
	state.equipped_weapon_id = backpack_manager.equipped_weapon.id if backpack_manager.equipped_weapon != null else &""

	var held_ids: Array[StringName] = []
	for relic in relic_handler._held_relics:
		held_ids.append(relic.id)
	state.held_relics = held_ids
	state.used_once_relics = relic_handler._used_once_relics.duplicate()
	state.adrenaline_needle_used = not relic_handler._adrenaline_needle_available

	state.quest_state = quest_manager._quest_state
	state.quest_node_id = quest_manager._quest_node_id
	state.lost_letter_location_id = quest_manager._lost_letter_location_id
	state.survivors_letter_count = quest_manager._survivors_letter_count

	state.shop_stock = _serialize_shop_stock()
	state.event_assignments = {}
	state.ruins_search_counters = node_interaction_manager._ruins_search_counters.duplicate()
	state.safe_house_states = _serialize_safe_house_states()

	return state


func _serialize_backpack_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append_array(_serialize_grid_items(backpack_manager.primary_grid, &"primary"))
	for i in range(backpack_manager.secondary_grids.size()):
		result.append_array(_serialize_grid_items(backpack_manager.secondary_grids[i], &"secondary_%d" % i))
	return result


func _serialize_pocket_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.append_array(_serialize_grid_items(backpack_manager.pocket_a, &"pocket_a"))
	result.append_array(_serialize_grid_items(backpack_manager.pocket_b, &"pocket_b"))
	return result


func _serialize_grid_items(grid: BackpackGrid, grid_type: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in grid.get_items():
		if item.id == &"gold":
			continue
		var pos := grid.get_item_position(item)
		result.append({
			"item": item,
			"grid_type": grid_type,
			"x": pos.get("x", 0),
			"y": pos.get("y", 0),
			"rotated": pos.get("rotated", false),
		})
	return result


func _serialize_shop_stock() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node_id in shop_manager._stock_by_node.keys():
		var slots: Array = shop_manager._stock_by_node[node_id]
		var slot_dicts: Array[Dictionary] = []
		for slot in slots:
			slot_dicts.append({
				"item": slot.item if slot.item != null else null,
				"quantity": slot.quantity,
				"buy_price": slot.buy_price,
				"sell_price": slot.sell_price,
				"is_fixed": slot.is_fixed,
			})
		result.append({
			"node_id": node_id,
			"slots": slot_dicts,
		})
	return result


func _serialize_safe_house_states() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for node_id in node_interaction_manager._safe_house_states.keys():
		var state: SafeHouseState = node_interaction_manager._safe_house_states[node_id]
		result.append({
			"node_id": node_id,
			"fridge_items": state.fridge_items.duplicate(),
			"scattered_items": state.scattered_items.duplicate(),
			"piggy_bank_gold": state.piggy_bank_gold,
			"anvil_uses_remaining": state.anvil_uses_remaining,
			"has_entered_before": state.has_entered_before,
		})
	return result


func _build_meta_state() -> MetaStateResource:
	var state := MetaStateResource.new()
	state.survivor_notes_progress = survivor_notes.get_all_progress()
	return state


func _restore_meta_state(meta: MetaStateResource) -> void:
	survivor_notes.load_all_progress(meta.survivor_notes_progress)


func _restore_adventure_state(state: AdventureStateResource) -> void:
	print("RESTORE: chapter=", state.chapter, " nodes=", state.nodes.size(), " player=", state.player_node_id, " prev=", state.previous_node_id)
	print("RESTORE: stamina=", state.stamina_current, "/", state.stamina_max, " gold=", state.gold, " backpack=", state.backpack_items.size(), " pocket=", state.pocket_items.size())

	current_chapter = state.chapter

	# Defensive: serialization may degrade StringName to String; force conversion
	for node in state.nodes:
		node.id = StringName(node.id)
		for i in range(node.connections.size()):
			node.connections[i] = StringName(node.connections[i])
	state.player_node_id = StringName(state.player_node_id)
	state.previous_node_id = StringName(state.previous_node_id)

	map_state.initialize_from_graph(state.nodes, state.player_node_id)
	map_state.previous_node_id = state.previous_node_id
	path_finder.initialize(map_state)

	current_stamina = Stamina.new()
	current_stamina.initialize(state.stamina_max)
	current_stamina._current_stamina = state.stamina_current
	_connect_stamina_signals()

	node_manager.initialize(map_state, path_finder, current_stamina)
	node_interaction_manager.initialize(map_state, node_manager, rng)

	backpack_manager.reset()
	backpack_manager.current_backpack_type = state.backpack_type
	backpack_manager._setup_backpack(state.backpack_type)
	backpack_manager._place_gold_item()
	backpack_manager.gold_count = state.gold

	var placed_count := 0
	for entry in state.backpack_items:
		var item = entry.get("item")
		if not (item is ItemData):
			print("RESTORE SKIP: backpack item not ItemData, type=", typeof(item))
			continue
		var grid := _get_grid_by_type(entry.get("grid_type", &""))
		if grid != null:
			grid.place(item, entry.get("x", 0), entry.get("y", 0), entry.get("rotated", false))
			placed_count += 1
	for entry in state.pocket_items:
		var item = entry.get("item")
		if not (item is ItemData):
			print("RESTORE SKIP: pocket item not ItemData, type=", typeof(item))
			continue
		var grid := _get_grid_by_type(entry.get("grid_type", &""))
		if grid != null:
			grid.place(item, entry.get("x", 0), entry.get("y", 0), entry.get("rotated", false))
			placed_count += 1
	print("RESTORE: placed ", placed_count, " items")

	if state.equipped_weapon_id != &"":
		for item in backpack_manager.get_total_items():
			if item.id == state.equipped_weapon_id:
				backpack_manager.equipped_weapon = item
				break

	relic_handler._held_relics.clear()
	relic_handler._used_once_relics = state.used_once_relics.duplicate()
	relic_handler._adrenaline_needle_available = not state.adrenaline_needle_used
	for relic_id in state.held_relics:
		var relic := RelicData.new()
		relic.id = relic_id
		relic_handler._held_relics.append(relic)

	quest_manager._quest_state = state.quest_state
	quest_manager._quest_node_id = state.quest_node_id
	quest_manager._lost_letter_location_id = state.lost_letter_location_id
	quest_manager._survivors_letter_count = state.survivors_letter_count
	if state.quest_state == QuestManager.QuestState.INACTIVE:
		quest_manager.start_chapter_quest(current_chapter, &"QUEST")

	shop_manager._stock_by_node.clear()
	for entry in state.shop_stock:
		var node_id: StringName = entry.get("node_id", &"")
		var slot_dicts: Array[Dictionary] = entry.get("slots", [])
		var slots: Array[ShopManager.ShopSlot] = []
		for slot_dict in slot_dicts:
			var item = slot_dict.get("item")
			if not (item is ItemData):
				item = ItemData.new()
			var slot := ShopManager.ShopSlot.new(item, slot_dict.get("quantity", 0), slot_dict.get("buy_price", 0), slot_dict.get("sell_price", 0))
			slot.is_fixed = slot_dict.get("is_fixed", false)
			slots.append(slot)
		shop_manager._stock_by_node[node_id] = slots

	node_interaction_manager._ruins_search_counters = state.ruins_search_counters.duplicate()
	node_interaction_manager._safe_house_states.clear()
	for entry in state.safe_house_states:
		var sh_state := SafeHouseState.new()
		sh_state.fridge_items = entry.get("fridge_items", [])
		sh_state.scattered_items = entry.get("scattered_items", [])
		sh_state.piggy_bank_gold = entry.get("piggy_bank_gold", 0)
		sh_state.anvil_uses_remaining = entry.get("anvil_uses_remaining", 0)
		sh_state.has_entered_before = entry.get("has_entered_before", false)
		var sh_node_id: StringName = entry.get("node_id", &"")
		node_interaction_manager._safe_house_states[sh_node_id] = sh_state

	print("RESTORE DONE: player_node=", map_state.player_node_id, " stamina=", current_stamina.current_stamina)


func _restore_combat_from_snapshot(snapshot: Dictionary) -> void:
	var node_id: StringName = snapshot.get("current_combat_node_id", &"")
	var enemy_type: GameEnums.EnemyType = snapshot.get("enemy_type", GameEnums.EnemyType.NORMAL)
	_start_combat(node_id, _get_enemy_data(enemy_type), enemy_type)

	if current_combat_manager != null and current_combat_manager.combat_state != null:
		var cs := current_combat_manager.combat_state
		cs.set_enemy_hp(snapshot.get("enemy_current_hp", cs.enemy_current_hp))
		cs.start_round(snapshot.get("round_number", 1))
		for debuff in snapshot.get("active_debuffs", []):
			cs.add_debuff(debuff as GameEnums.DebuffType)
		cs.set_boss_emergency_heal_used(snapshot.get("boss_emergency_heal_used", false))


func _get_grid_by_type(grid_type: StringName) -> BackpackGrid:
	if grid_type == &"primary":
		return backpack_manager.primary_grid
	if grid_type == &"pocket_a":
		return backpack_manager.pocket_a
	if grid_type == &"pocket_b":
		return backpack_manager.pocket_b
	if grid_type.begins_with("secondary_"):
		var idx_str := grid_type.replace("secondary_", "")
		var idx := int(idx_str)
		if idx >= 0 and idx < backpack_manager.secondary_grids.size():
			return backpack_manager.secondary_grids[idx]
	return null


func _setup_chapter(chapter: int) -> void:
	current_chapter = chapter

	if chapter == 4:
		survivor_notes.add_progress(&"martyr", 1)

	# Generate map
	var nodes := map_generator.generate(chapter)
	map_state.initialize_from_graph(nodes, &"START")
	path_finder.initialize(map_state)

	# Create stamina for this chapter
	var stamina := _create_stamina()
	current_stamina = stamina
	_connect_stamina_signals()
	node_manager.initialize(map_state, path_finder, stamina)
	node_interaction_manager.initialize(map_state, node_manager, rng)

	# Chapter-specific setup
	quest_manager.start_chapter_quest(chapter, &"QUEST")

	# Relic chapter-start effects
	var granted_relics := relic_handler.on_chapter_start()
	for relic in granted_relics:
		if relic != null:
			# TODO: add relic to backpack / relic handler
			pass

	chapter_started.emit(chapter)


func _create_stamina() -> Stamina:
	var stamina := Stamina.new()
	var max_stamina := 12 + relic_handler.get_max_stamina_bonus() + survivor_notes.get_max_stamina_bonus()
	stamina.initialize(max_stamina)
	return stamina


func _connect_stamina_signals() -> void:
	if current_stamina == null:
		return
	if current_stamina.stamina_changed.is_connected(_on_stamina_value_changed):
		current_stamina.stamina_changed.disconnect(_on_stamina_value_changed)
	current_stamina.stamina_changed.connect(_on_stamina_value_changed)
	if current_stamina.max_stamina_changed.is_connected(_on_stamina_value_changed):
		current_stamina.max_stamina_changed.disconnect(_on_stamina_value_changed)
	current_stamina.max_stamina_changed.connect(_on_stamina_value_changed)


func _on_stamina_value_changed(_new_value: int, _old_value: int) -> void:
	stamina_changed.emit(current_stamina.current_stamina, current_stamina.max_stamina)


func return_to_exploration() -> void:
	if current_state == GameState.EVENT and current_interaction_node_id != &"":
		node_interaction_manager.convert_node_to_road(current_interaction_node_id)
	_change_state(GameState.MAP_EXPLORATION)


func _change_state(new_state: int) -> void:
	var old_state := current_state
	current_state = new_state
	state_changed.emit(new_state, old_state)


# === Signal Handlers: Node Traversal ===

func _on_player_moved(_to_node_id: StringName, _stamina_cost: int) -> void:
	# TODO: trigger auto-save via save_load_manager.request_auto_save()
	pass


func _on_node_visited(node_id: StringName, node_type: GameEnums.MapNodeType) -> void:
	if current_stamina.current_stamina <= 0:
		player_died.emit()
		return

	# Route to interaction system
	node_interaction_manager.process_node_arrival(node_id)

	# Survivor Notes: Wayfarer & Pathfinder
	if node_type != GameEnums.MapNodeType.ROAD and node_type != GameEnums.MapNodeType.START:
		non_road_nodes_visited += 1
		survivor_notes.add_progress(&"wayfarer", 1)
		if non_road_nodes_visited >= 75:
			# Pathfinder is "single run" threshold; add_progress handles duplicate calls safely
			survivor_notes.add_progress(&"pathfinder", non_road_nodes_visited)


func _on_node_cleared(node_id: StringName) -> void:
	# TODO: check if chapter boss defeated -> ending_manager.check_chapter4_boss_outcome()
	# TODO: request auto-save
	pass


# === Signal Handlers: Node Interaction ===

func _start_combat(node_id: StringName, enemy: EnemyData, enemy_type: GameEnums.EnemyType) -> void:
	current_combat_node_id = node_id
	_current_enemy_type = enemy_type
	var deck := _create_default_deck()
	current_combat_manager = CombatManager.new()
	current_combat_manager.initialize(enemy, enemy_type, current_stamina, deck, backpack_manager, null, null, 3, rng)
	current_combat_manager.card_played.connect(_on_card_played)
	current_combat_manager.combat_ended.connect(_on_combat_ended)
	combat_prepared.emit(current_combat_manager)
	_change_state(GameState.COMBAT)


func _on_combat_triggered(node_id: StringName, enemy_type: GameEnums.EnemyType) -> void:
	survivor_notes.add_progress(&"combat_master", 1)
	_start_combat(node_id, _get_enemy_data(enemy_type), enemy_type)


func _on_boss_combat_triggered(node_id: StringName, boss_data: EnemyData) -> void:
	var enemy := boss_data if boss_data != null else _get_enemy_data(GameEnums.EnemyType.BOSS)
	_start_combat(node_id, enemy, GameEnums.EnemyType.BOSS)


func _on_shop_opened(node_id: StringName) -> void:
	current_interaction_node_id = node_id

	var has_quest := quest_manager.get_quest_state() == QuestManager.QuestState.ACCEPTED
	var lost_letter_location := quest_manager.get_lost_letter_location()
	var has_lost_letter_here := has_quest and lost_letter_location == node_id

	shop_manager.ensure_stock_for_node(node_id, current_chapter, has_lost_letter_here, 5)
	_change_state(GameState.SHOP)
	# TODO: open shop UI overlay


func _on_gold_changed(new_amount: int) -> void:
	var delta := new_amount - _last_gold_count
	if delta > 0:
		survivor_notes.add_progress(&"hoarder", delta)
		survivor_notes.add_progress(&"miser", delta)
	_last_gold_count = new_amount


func notify_consumable_used(item_id: StringName, from_pocket: bool) -> void:
	survivor_notes.add_progress(&"survival_expert", 1)
	if from_pocket:
		survivor_notes.add_progress(&"magician", 1)
	match item_id:
		&"energy_drink":
			survivor_notes.add_progress(&"partner", 7 + survivor_notes.get_energy_drink_bonus())
			survivor_notes.add_progress(&"spokesperson", 1)
		&"flashlight":
			survivor_notes.add_progress(&"electrician", 1)
			survivor_notes.add_progress(&"adventurer", 1)


func use_item_in_backpack(item: ItemData) -> bool:
	if item.item_type != GameEnums.ItemType.CONSUMABLE:
		return false
	match item.id:
		&"energy_drink":
			var bonus := survivor_notes.get_energy_drink_bonus()
			current_stamina.restore(7 + bonus)
			backpack_manager.remove_item(item)
			notify_consumable_used(item.id, false)
			return true
		&"flashlight":
			_use_flashlight_in_backpack()
			backpack_manager.remove_item(item)
			notify_consumable_used(item.id, false)
			return true
		&"stone", &"torch":
			return false
		&"whetstone":
			return false
		&"safe_house_key":
			return false
		&"password_box":
			_open_password_box(item)
			return false
	return false


func _use_flashlight_in_backpack() -> void:
	var hidden_nodes: Array[MapNodeData] = []
	for n in map_state.nodes.values():
		var node := n as MapNodeData
		if node.visibility == GameEnums.MapNodeVisibility.UNEXPLORED:
			hidden_nodes.append(node)
	var reveal_count := 2 + survivor_notes.get_flashlight_reveal_bonus()
	hidden_nodes.shuffle()
	for i in range(mini(reveal_count, hidden_nodes.size())):
		hidden_nodes[i].visibility = GameEnums.MapNodeVisibility.REVEALED


func _open_password_box(item: ItemData) -> void:
	var password: int = item.metadata.get("password", 0)
	if password == 0:
		password = rng.randi_range(10, 99)
		item.metadata["password"] = password
	_current_password_box_item = item
	password_box_opened.emit(item, current_stamina.current_stamina, current_stamina.max_stamina)


func submit_password_guess(guessed: int) -> void:
	if _current_password_box_item == null:
		return
	if current_stamina.current_stamina <= 0:
		return
	current_stamina.deduct(1)
	var actual: int = _current_password_box_item.metadata.get("password", 0)
	if guessed == actual:
		var reward := _grant_password_box_reward()
		backpack_manager.remove_item(_current_password_box_item)
		_current_password_box_item = null
		password_box_reward_granted.emit(reward)
	elif guessed > actual:
		password_box_hint.emit("密码比 %d 小。" % guessed)
	else:
		password_box_hint.emit("密码比 %d 大。" % guessed)


func _grant_password_box_reward() -> String:
	var roll := rng.randf()
	if roll < 0.40:
		var key := ItemData.new()
		key.id = &"safe_house_key"
		key.display_name = "安全屋房卡"
		key.item_type = GameEnums.ItemType.CONSUMABLE
		key.width = 1
		key.height = 1
		backpack_manager.add_item(key)
		return "安全屋房卡 ×1"
	elif roll < 0.60:
		backpack_manager.add_gold(20)
		return "金币 ×20"
	elif roll < 0.80:
		var relic := ItemData.new()
		relic.id = &"heart_of_hope"
		relic.display_name = "希望之心"
		relic.item_type = GameEnums.ItemType.RELIC
		relic.width = 1
		relic.height = 1
		backpack_manager.add_item(relic)
		return "已解锁信物 ×1"
	elif roll < 0.95:
		backpack_manager.add_gold(30)
		return "金币 ×30"
	elif roll < 0.975:
		return "当前章节已解锁武器（待实现）"
	else:
		return "当前章节已解锁背包（待实现）"


func _consume_safe_house_key() -> bool:
	for item in backpack_manager.get_total_items():
		if item.id == &"safe_house_key":
			backpack_manager.remove_item(item)
			return true
	return false


func _on_safe_house_opened(node_id: StringName) -> void:
	if not _consume_safe_house_key():
		print("需要安全屋房卡才能进入")
		return

	current_interaction_node_id = node_id
	var scholar_stage := survivor_notes.get_entry_completed_stage(&"scholar")
	var state := node_interaction_manager.get_or_create_safe_house_state(node_id, current_chapter, scholar_stage)
	state.has_entered_before = true

	_change_state(GameState.SAFE_HOUSE)
	quest_manager.on_safe_house_entered(node_id)
	survivor_notes.add_progress(&"scholar", 1)
	safe_house_prepared.emit(node_id)


func _on_event_triggered(node_id: StringName, _event_type: StringName) -> void:
	current_interaction_node_id = node_id
	survivor_notes.add_progress(&"mischief_maker", 1)
	_change_state(GameState.EVENT)
	var node := map_state.get_node_by_id(node_id)
	var event_type := node.event_type if node != null and node.event_type != &"" else event_manager.pick_event_type(current_chapter)
	_current_event_type = event_type
	_present_event(event_type)


func _present_event(event_type: StringName) -> void:
	var title: String = EVENT_TITLES.get(event_type, "突发事件")

	match event_type:
		&"robbery":
			event_presented.emit(title, "你遇到了劫匪！支付一半金币还是战斗？", ["支付一半金币", "战斗"])
		&"hitchhike":
			event_presented.emit(title, "一个陌生人愿意载你一程。支付2金币传送到安全位置。", ["支付2金币", "拒绝"])
		&"corpse":
			event_presented.emit(title, "你发现了一具尸体。要花费1体力搜索吗？", ["搜索", "离开"])
		&"gambler":
			event_presented.emit(title, "一个赌徒邀请你玩21点。下注1金币试试手气？", ["下注1金币", "拒绝"])
		&"theft", &"locked_box", &"dying_embers":
			var outcome := event_manager.resolve_event(event_type, current_chapter)
			var msg := _format_event_result(event_type, outcome)
			event_result_presented.emit(title, msg)
		&"destroyed_camp":
			# resolve 会触发 combat_triggered 信号，直接进入战斗
			event_manager.resolve_event(event_type, current_chapter)
		&"rogue_market":
			# TODO: shop_opened_temporarily 信号未被连接，暂时展示提示
			event_result_presented.emit(title, "你发现了一个临时黑市，但店主已经离开了。")
		_:
			event_result_presented.emit(title, "什么也没发生。")


func _format_event_result(event_type: StringName, outcome: Dictionary) -> String:
	match event_type:
		&"theft":
			if outcome.get("blocked", false):
				return "徽章阻止了盗窃！"
			var stolen: Array = outcome.get("stolen_items", [])
			if stolen.is_empty():
				return "小偷试图偷窃，但你身上没有东西可偷。"
			var names: Array[String] = []
			for item in stolen:
				if item is ItemData:
					names.append(item.display_name)
			return "小偷盗走了你的：" + ", ".join(names)
		&"locked_box":
			if outcome.get("received_box", false):
				return "你获得了一个密码箱！"
			return "背包空间不足，无法携带密码箱。"
		&"dying_embers":
			var restored: int = outcome.get("stamina_restored", 0)
			return "温暖的余烬恢复了%d点体力。" % restored
		_:
			return "事件已结算。"


func resolve_event_choice(choice_index: int) -> void:
	match _current_event_type:
		&"robbery":
			var choice := &"pay_half" if choice_index == 0 else &"fight"
			var outcome := event_manager.resolve_robbery_choice(choice)
			if choice == &"fight" and outcome.get("combat", false):
				return
			var title: String = EVENT_TITLES.get(_current_event_type, "突发事件")
			var paid: int = outcome.get("paid", 0)
			var msg := "你支付了%d金币，劫匪放你离开。" % paid
			event_result_presented.emit(title, msg)
		&"hitchhike":
			if choice_index == 0:
				var target := _find_random_teleport_target()
				if target != &"":
					# resolve_hitchhike_teleport emits teleport_requested, which _on_teleport_requested handles
					event_manager.resolve_hitchhike_teleport(target)
				var title: String = EVENT_TITLES.get(_current_event_type, "突发事件")
				event_result_presented.emit(title, "你支付了2金币，被传送到了新的位置。")
			else:
				return_to_exploration()
		&"corpse":
			if choice_index == 0:
				var outcome := event_manager.resolve_corpse_search(current_chapter)
				var title: String = EVENT_TITLES.get(_current_event_type, "突发事件")
				var gold: int = outcome.get("loot_gold", 0)
				event_result_presented.emit(title, "你花费1体力搜索了尸体，发现了%d金币。" % gold)
			else:
				return_to_exploration()
		&"gambler":
			if choice_index == 0:
				var outcome := event_manager.resolve_gambler_bet(1)
				var title: String = EVENT_TITLES.get(_current_event_type, "突发事件")
				var result: String = outcome.get("result", "")
				var delta: int = outcome.get("gold_delta", 0)
				var msg := ""
				match result:
					"win":  msg = "你赢了！获得%d金币。" % delta
					"lose": msg = "你输了，失去了%d金币。" % abs(delta)
					"push": msg = "平局，金币退还。"
				event_result_presented.emit(title, msg)
			else:
				return_to_exploration()


func _find_random_teleport_target() -> StringName:
	var candidates: Array[MapNodeData] = []
	for n in map_state.nodes.values():
		var node := n as MapNodeData
		if node.node_type != GameEnums.MapNodeType.BOSS and node.node_type != GameEnums.MapNodeType.START:
			candidates.append(node)
	if candidates.is_empty():
		return &""
	candidates.shuffle()
	return candidates[0].id


func _on_ruins_searched(node_id: StringName, search_count: int) -> void:
	node_interaction_manager.record_ruins_search(node_id)
	survivor_notes.add_progress(&"scavenger", 1)
	if search_count >= 1:
		# TODO: second search triggers loot roll from EventManager / loot system
		pass


func _on_quest_triggered(_node_id: StringName, _quest_state: int) -> void:
	quest_manager.accept_quest()


# === Signal Handlers: Event Outcomes ===

func _on_teleport_requested(target_node_id: StringName) -> void:
	node_manager.move_to(target_node_id)


func _on_event_combat_triggered(enemy_type: GameEnums.EnemyType, _is_event_combat: bool) -> void:
	_start_combat(current_interaction_node_id, _get_enemy_data(enemy_type), enemy_type)


func _on_event_stamina_changed(amount: int) -> void:
	if amount > 0:
		current_stamina.restore(amount)
	elif amount < 0:
		current_stamina.deduct(-amount)


# === Signal Handlers: Combat (TODO) ===

func _create_default_deck() -> Array[ActionCardData]:
	var deck: Array[ActionCardData] = []

	var unarmed := ActionCardData.new()
	unarmed.id = &"unarmed_attack"
	unarmed.display_name = "Unarmed Attack"
	unarmed.stamina_cost = 1
	unarmed.effect = GameEnums.ActionCardEffect.UNARMED_ATTACK
	unarmed.base_value = 3
	deck.append(unarmed)

	var weapon := ActionCardData.new()
	weapon.id = &"weapon_attack"
	weapon.display_name = "Weapon Attack"
	weapon.stamina_cost = 1
	weapon.effect = GameEnums.ActionCardEffect.WEAPON_ATTACK
	weapon.base_value = 7
	deck.append(weapon)

	var heavy := ActionCardData.new()
	heavy.id = &"heavy_strike"
	heavy.display_name = "Heavy Strike"
	heavy.stamina_cost = 1
	heavy.effect = GameEnums.ActionCardEffect.UNARMED_ATTACK
	heavy.base_value = 4
	deck.append(heavy)

	var dodge := ActionCardData.new()
	dodge.id = &"dodge"
	dodge.display_name = "Dodge"
	dodge.stamina_cost = 2
	dodge.effect = GameEnums.ActionCardEffect.DODGE
	deck.append(dodge)

	var courage := ActionCardData.new()
	courage.id = &"summon_courage"
	courage.display_name = "Summon Courage"
	courage.stamina_cost = 1
	courage.effect = GameEnums.ActionCardEffect.SUMMON_COURAGE
	deck.append(courage)

	var flee := ActionCardData.new()
	flee.id = &"flee"
	flee.display_name = "Flee"
	flee.stamina_cost = 5
	flee.effect = GameEnums.ActionCardEffect.FLEE
	deck.append(flee)

	return deck


func _get_enemy_data(enemy_type: GameEnums.EnemyType) -> EnemyData:
	var enemy := EnemyData.new()
	match enemy_type:
		GameEnums.EnemyType.NORMAL:
			enemy.id = &"normal_enemy"
			enemy.display_name = "Normal Enemy"
			enemy.base_hp = 14
			enemy.base_attack = 4
		GameEnums.EnemyType.HARD:
			enemy.id = &"hard_enemy"
			enemy.display_name = "Hard Enemy"
			enemy.base_hp = 20
			enemy.base_attack = 6
		GameEnums.EnemyType.BOSS:
			enemy.id = &"boss_enemy"
			enemy.display_name = "Boss"
			enemy.base_hp = 50
			enemy.base_attack = 10
	enemy.enemy_type = enemy_type
	return enemy


func _try_death_save() -> bool:
	var restored_stamina := relic_handler.on_death_save(current_stamina.current_stamina)
	if restored_stamina > 0:
		var deficit := restored_stamina - current_stamina.current_stamina
		if deficit > 0:
			current_stamina.restore(deficit)
		return true
	return false


func _on_combat_ended(result: GameEnums.CombatPhase) -> void:
	var was_boss: bool = _current_enemy_type == GameEnums.EnemyType.BOSS
	current_combat_manager = null
	_current_enemy_type = GameEnums.EnemyType.NORMAL

	match result:
		GameEnums.CombatPhase.VICTORY:
			quest_manager.on_combat_victory(current_combat_node_id)
			node_interaction_manager.mark_node_cleared(current_combat_node_id)

			if current_stamina.current_stamina <= 0 and not _try_death_save():
				player_died.emit()
				return

			if was_boss:
				_change_state(GameState.ENDING)
				adventure_ended.emit(&"victory")
				return

			var loot := _generate_combat_loot()
			loot_generated.emit(loot.gold, loot.items)

		GameEnums.CombatPhase.DEFEAT:
			if _try_death_save():
				return_to_exploration()
			else:
				player_died.emit()

		GameEnums.CombatPhase.FLED:
			survivor_notes.add_progress(&"escape_master", 1)
			if current_stamina.current_stamina <= 0:
				if _try_death_save():
					return_to_exploration()
				else:
					player_died.emit()
			else:
				if map_state.previous_node_id != &"":
					map_state.retreat_to_previous_node()
				else:
					var node := map_state.get_node_by_id(current_combat_node_id)
					if node != null and node.visibility == GameEnums.MapNodeVisibility.VISITED:
						node.visibility = GameEnums.MapNodeVisibility.REVEALED
				return_to_exploration()


func _generate_combat_loot() -> Dictionary:
	var gold := rng.randi_range(5, 15)
	var items: Array[ItemData] = []

	var consumable_pool: Dictionary = {
		"能量饮料": &"energy_drink",
		"手电筒": &"flashlight",
		"火把": &"torch",
		"磨刀石": &"whetstone",
		"石头": &"stone",
	}
	var picked_name: String = consumable_pool.keys()[rng.randi_range(0, consumable_pool.size() - 1)]

	var item := ItemData.new()
	item.id = consumable_pool[picked_name]
	item.display_name = picked_name
	item.item_type = GameEnums.ItemType.CONSUMABLE
	match item.id:
		&"flashlight", &"torch":
			item.width = 1
			item.height = 2
		_:
			item.width = 1
			item.height = 1
	items.append(item)

	return {"gold": gold, "items": items}


func _on_card_played(card: ActionCardData) -> void:
	match card.effect:
		GameEnums.ActionCardEffect.DODGE:
			survivor_notes.add_progress(&"sports_enthusiast", 1)
		GameEnums.ActionCardEffect.UNARMED_ATTACK, \
		GameEnums.ActionCardEffect.WEAPON_ATTACK, \
		GameEnums.ActionCardEffect.SUMMON_COURAGE:
			survivor_notes.add_progress(&"improviser", 1)
		_:
			pass


# === Signal Handlers: Ending ===

func _on_false_ending(_stats: EndingManager.AdventureStats) -> void:
	_change_state(GameState.ENDING)
	# TODO: show false ending UI, then return to main menu


func _on_true_ending(_stats: EndingManager.AdventureStats) -> void:
	_change_state(GameState.ENDING)
	# TODO: show true ending UI, then return to main menu


func _on_run_completed(ending_type: StringName, _stats: EndingManager.AdventureStats) -> void:
	adventure_ended.emit(ending_type)
	# TODO: commit meta progression (SurvivorNotes, unlocked endings, difficulty)
	# TODO: return to main menu

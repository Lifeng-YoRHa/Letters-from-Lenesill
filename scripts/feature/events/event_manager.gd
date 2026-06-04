class_name EventManager
extends RefCounted

signal event_resolved(event_type: StringName, outcome: Dictionary)
signal combat_triggered(enemy_type: GameEnums.EnemyType, is_event_combat: bool)
signal loot_granted(items: Array[ItemData], gold: int)
signal stamina_changed(amount: int)
signal gold_changed(amount: int)
signal teleport_requested(target_node_id: StringName)
signal shop_opened_temporarily()
signal locked_box_granted()

var _rng: RandomNumberGenerator
var _backpack_manager: BackpackManager
var _relic_handler: RelicHandler


func initialize(rng: RandomNumberGenerator, backpack_manager: BackpackManager, relic_handler: RelicHandler) -> void:
	_rng = rng
	_backpack_manager = backpack_manager
	_relic_handler = relic_handler


func resolve_event(event_type: StringName, chapter: int) -> Dictionary:
	match event_type:
		&"theft":
			return _resolve_theft()
		&"robbery":
			return _resolve_robbery()
		&"hitchhike":
			return _resolve_hitchhike()
		&"corpse":
			return _resolve_corpse(chapter)
		&"locked_box":
			return _resolve_locked_box()
		&"destroyed_camp":
			return _resolve_destroyed_camp()
		&"gambler":
			return _resolve_gambler()
		&"rogue_market":
			return _resolve_rogue_market()
		&"dying_embers":
			return _resolve_dying_embers()
		_:
			return {}


func _resolve_theft() -> Dictionary:
	if _relic_handler != null and _relic_handler.is_theft_blocked():
		return {"blocked": true, "message": "Badge blocked the theft."}

	var backpack_items := _backpack_manager.primary_grid.get_items()
	for grid in _backpack_manager.secondary_grids:
		backpack_items.append_array(grid.get_items())

	var stolen: Array[ItemData] = []
	if backpack_items.size() > 0:
		var count := mini(2, backpack_items.size())
		for i in range(count):
			var idx := _rng.randi_range(0, backpack_items.size() - 1)
			var item := backpack_items[idx]
			_backpack_manager.remove_item(item)
			stolen.append(item)
			backpack_items.remove_at(idx)

	return {"stolen_items": stolen, "message": "Theft occurred."}


func _resolve_robbery() -> Dictionary:
	return {"choices": ["pay_half", "fight"], "message": "Robbery! Pay half gold or fight."}


func resolve_robbery_choice(choice: StringName) -> Dictionary:
	match choice:
		&"pay_half":
			var payment := _backpack_manager.gold_count / 2
			_backpack_manager.remove_gold(payment)
			return {"paid": payment, "resolved": true}
		&"fight":
			combat_triggered.emit(GameEnums.EnemyType.NORMAL, true)
			return {"combat": true, "resolved": false}
		_:
			return {}


func _resolve_hitchhike() -> Dictionary:
	return {"cost": 2, "message": "Pay 2 gold to teleport to any non-Boss node."}


func resolve_hitchhike_teleport(target_node_id: StringName) -> Dictionary:
	_backpack_manager.remove_gold(2)
	teleport_requested.emit(target_node_id)
	return {"teleported": true, "cost": 2}


func _resolve_corpse(chapter: int) -> Dictionary:
	return {"cost": 1, "message": "Spend 1 stamina to search the corpse."}


func resolve_corpse_search(chapter: int) -> Dictionary:
	# Deduct stamina via signal (upstream handles actual deduction)
	stamina_changed.emit(-1)
	# Loot roll from ruins 2nd search table (simplified)
	var gold := _rng.randi_range(3, 8)
	return {"loot_gold": gold, "resolved": true}


func _resolve_locked_box() -> Dictionary:
	var box := ItemData.new()
	box.id = &"password_box"
	box.display_name = "密码箱"
	box.item_type = GameEnums.ItemType.CONSUMABLE
	box.width = 2
	box.height = 2
	box.rotatable = true
	if _backpack_manager.can_fit_anywhere(box):
		_backpack_manager.add_item(box)
		locked_box_granted.emit()
		return {"received_box": true}
	return {"received_box": false, "message": "Not enough inventory space."}


func _resolve_destroyed_camp() -> Dictionary:
	combat_triggered.emit(GameEnums.EnemyType.HARD, true)
	return {"combat": true, "enemy_type": GameEnums.EnemyType.HARD}


func _resolve_gambler() -> Dictionary:
	return {"min_bet": 1, "max_bet": mini(10, _backpack_manager.gold_count), "message": "Wager on Blackjack."}


func resolve_gambler_bet(bet: int) -> Dictionary:
	if bet < 1 or bet > _backpack_manager.gold_count or bet > 10:
		return {"error": true, "message": "Invalid bet."}

	_backpack_manager.remove_gold(bet)

	# Simplified Blackjack resolution
	var player_score := _rng.randi_range(16, 22)
	var dealer_score := _rng.randi_range(16, 22)

	if player_score > 21:
		return {"result": "lose", "gold_delta": -bet}
	if dealer_score > 21 or player_score > dealer_score:
		_backpack_manager.add_gold(bet * 2)
		return {"result": "win", "gold_delta": bet}
	if player_score == dealer_score:
		_backpack_manager.add_gold(bet)
		return {"result": "push", "gold_delta": 0}
	return {"result": "lose", "gold_delta": -bet}


func _resolve_rogue_market() -> Dictionary:
	shop_opened_temporarily.emit()
	return {"shop": true, "message": "A temporary Black Market appears."}


func _resolve_dying_embers() -> Dictionary:
	stamina_changed.emit(8)
	return {"stamina_restored": 8, "message": "Warm embers restore 8 stamina."}


func get_event_probability_table(chapter: int) -> Dictionary:
	var base := {
		&"theft":         [0.10, 0.08, 0.06, 0.05, 0.00],
		&"robbery":       [0.10, 0.11, 0.12, 0.12, 0.00],
		&"hitchhike":     [0.13, 0.11, 0.10, 0.09, 0.00],
		&"corpse":        [0.11, 0.14, 0.16, 0.18, 0.35],
		&"locked_box":    [0.09, 0.11, 0.11, 0.13, 0.34],
		&"destroyed_camp":[0.06, 0.10, 0.12, 0.12, 0.04],
		&"gambler":       [0.13, 0.11, 0.09, 0.09, 0.00],
		&"rogue_market":  [0.12, 0.11, 0.10, 0.08, 0.00],
		&"dying_embers":  [0.16, 0.13, 0.14, 0.14, 0.27],
	}
	var result := {}
	var idx := mini(chapter - 1, 4)
	for key in base.keys():
		result[key] = base[key][idx]
	return result


func pick_event_type(chapter: int) -> StringName:
	var table := get_event_probability_table(chapter)
	if _relic_handler != null and _relic_handler.has_relic(&"badge"):
		# Remove theft and robbery, renormalize
		table.erase(&"theft")
		table.erase(&"robbery")
		var total := 0.0
		for v in table.values():
			total += v
		for key in table.keys():
			table[key] = table[key] / total

	var roll := _rng.randf()
	var cumulative := 0.0
	for key in table.keys():
		cumulative += table[key]
		if roll <= cumulative:
			return key
	return &"dying_embers"


# === Ruins Search ===

func resolve_ruins_search(
	search_count: int,
	chapter: int,
	unlocked_relics: Array[StringName],
	available_weapons: Array[WeaponData],
	available_backpacks: Array[StringName]
) -> Dictionary:
	var result := {
		"gold": 0,
		"items": [] as Array[ItemData],
		"stamina_cost": search_count + 1,
		"exhausted": search_count >= 2,
		"backpack_reward": &"",
	}

	var roll := _rng.randf()
	var reward_type := _resolve_ruins_reward_type(search_count, roll)

	match reward_type:
		&"gold_7":
			result.gold = 7
		&"gold_13":
			result.gold = 13
		&"gold_20":
			result.gold = 20
		&"consumable_1", &"consumable_2", &"consumable_3":
			var count: int = int(str(reward_type).split("_")[1])
			for i in range(count):
				result.items.append(_roll_consumable_item())
		&"safe_house_key":
			var key := ItemData.new()
			key.id = &"safe_house_key"
			key.display_name = "安全屋房卡"
			key.item_type = GameEnums.ItemType.CONSUMABLE
			key.width = 1
			key.height = 1
			result.items.append(key)
		&"relic":
			if unlocked_relics.size() > 0:
				var relic_id := unlocked_relics[_rng.randi_range(0, unlocked_relics.size() - 1)]
				var relic := ItemData.new()
				relic.id = relic_id
				relic.display_name = _get_relic_display_name(relic_id)
				relic.item_type = GameEnums.ItemType.RELIC
				relic.width = 1
				relic.height = 1
				result.items.append(relic)
		&"weapon":
			if available_weapons.size() > 0:
				var weapon_data := available_weapons[_rng.randi_range(0, available_weapons.size() - 1)]
				var weapon := ItemData.new()
				weapon.id = weapon_data.id
				weapon.display_name = weapon_data.display_name
				weapon.item_type = GameEnums.ItemType.WEAPON
				weapon.width = weapon_data.size.x
				weapon.height = weapon_data.size.y
				result.items.append(weapon)
		&"backpack":
			if available_backpacks.size() > 0:
				result.backpack_reward = available_backpacks[_rng.randi_range(0, available_backpacks.size() - 1)]

	return result


func _resolve_ruins_reward_type(search_count: int, roll: float) -> StringName:
	# Cumulative probability tables per search_count (0=1st, 1=2nd, 2=3rd)
	var tables: Array[Array] = [
		# 1st search
		[
			{&"type": &"consumable_1", &"threshold": 0.34},
			{&"type": &"gold_7",        &"threshold": 0.51},
			{&"type": &"consumable_2", &"threshold": 0.72},
			{&"type": &"gold_13",       &"threshold": 0.85},
			{&"type": &"consumable_3", &"threshold": 0.93},
			{&"type": &"gold_20",       &"threshold": 0.96},
			{&"type": &"safe_house_key",&"threshold": 0.99},
			{&"type": &"relic",         &"threshold": 1.00},
		],
		# 2nd search
		[
			{&"type": &"consumable_1", &"threshold": 0.10},
			{&"type": &"gold_7",        &"threshold": 0.18},
			{&"type": &"consumable_2", &"threshold": 0.55},
			{&"type": &"gold_13",       &"threshold": 0.72},
			{&"type": &"consumable_3", &"threshold": 0.82},
			{&"type": &"gold_20",       &"threshold": 0.88},
			{&"type": &"safe_house_key",&"threshold": 0.95},
			{&"type": &"relic",         &"threshold": 0.98},
			{&"type": &"weapon",        &"threshold": 0.99},
			{&"type": &"backpack",      &"threshold": 1.00},
		],
		# 3rd search
		[
			{&"type": &"consumable_1", &"threshold": 0.06},
			{&"type": &"gold_7",        &"threshold": 0.09},
			{&"type": &"consumable_2", &"threshold": 0.35},
			{&"type": &"gold_13",       &"threshold": 0.42},
			{&"type": &"consumable_3", &"threshold": 0.63},
			{&"type": &"gold_20",       &"threshold": 0.83},
			{&"type": &"safe_house_key",&"threshold": 0.92},
			{&"type": &"relic",         &"threshold": 0.96},
			{&"type": &"weapon",        &"threshold": 0.98},
			{&"type": &"backpack",      &"threshold": 1.00},
		],
	]

	var table: Array = tables[search_count] if search_count < tables.size() else tables[0]
	for entry in table:
		if roll <= entry[&"threshold"]:
			return entry[&"type"]
	return &"consumable_1"


func _roll_consumable_item() -> ItemData:
	var roll := _rng.randf()
	var item := ItemData.new()
	item.item_type = GameEnums.ItemType.CONSUMABLE
	item.width = 1
	item.height = 1

	if roll < 0.23:
		item.id = &"whetstone"
		item.display_name = "磨刀石"
	elif roll < 0.34:
		item.id = &"stone"
		item.display_name = "石块"
	elif roll < 0.66:
		item.id = &"energy_drink"
		item.display_name = "能量饮料"
	elif roll < 0.82:
		item.id = &"flashlight"
		item.display_name = "手电筒"
		item.height = 2
	else:
		item.id = &"torch"
		item.display_name = "火把"
		item.height = 2

	return item


func _get_relic_display_name(relic_id: StringName) -> String:
	var path := "res://data/relics/%s.tres" % relic_id
	if ResourceLoader.exists(path):
		var data := load(path) as RelicData
		if data != null:
			return data.display_name
	return str(relic_id)


# === Combat Loot ===

func resolve_combat_loot(
	enemy_type: GameEnums.EnemyType,
	chapter: int,
	unlocked_relics: Array[StringName],
	held_relics: Array[RelicData]
) -> Dictionary:
	var is_hard := enemy_type == GameEnums.EnemyType.HARD
	var clamped_chapter := clampi(chapter, 1, 5)
	var result := {
		"gold": 0,
		"items": [] as Array[ItemData],
	}

	# Roll gold amount
	result.gold = _roll_combat_gold(is_hard, clamped_chapter, _rng.randf())

	# Roll consumable count and types
	var consumable_count := _roll_combat_consumable_count(is_hard, clamped_chapter, _rng.randf())
	for i in range(consumable_count):
		result.items.append(_roll_combat_consumable(clamped_chapter, is_hard))

	# Roll relics (hard combat only)
	if is_hard:
		var relic_count := _roll_combat_relic_count(clamped_chapter, _rng.randf())
		var available_relics := _filter_available_relics(unlocked_relics, held_relics)
		for i in range(mini(relic_count, available_relics.size())):
			var idx := _rng.randi_range(0, available_relics.size() - 1)
			var relic_id := available_relics[idx]
			var relic := ItemData.new()
			relic.id = relic_id
			relic.display_name = _get_relic_display_name(relic_id)
			relic.item_type = GameEnums.ItemType.RELIC
			relic.width = 1
			relic.height = 1
			result.items.append(relic)
			available_relics.remove_at(idx)

	return result


func _filter_available_relics(unlocked_relics: Array[StringName], held_relics: Array[RelicData]) -> Array[StringName]:
	var held_ids: Array[StringName] = []
	for held in held_relics:
		held_ids.append(held.id)
	var available: Array[StringName] = []
	for relic_id in unlocked_relics:
		if not held_ids.has(relic_id):
			available.append(relic_id)
	return available


func _roll_combat_gold(is_hard: bool, chapter: int, roll: float) -> int:
	var tables: Dictionary = _GOLD_TABLES["hard" if is_hard else "normal"]
	var table: Array = tables.get(chapter, tables.get(1, []))
	return _roll_from_table(roll, table)


func _roll_combat_consumable_count(is_hard: bool, chapter: int, roll: float) -> int:
	var tables: Dictionary = _CONSUMABLE_COUNT_TABLES["hard" if is_hard else "normal"]
	var table: Array = tables.get(chapter, tables.get(1, []))
	return _roll_from_table(roll, table)


func _roll_combat_consumable(chapter: int, is_hard: bool) -> ItemData:
	var tables: Dictionary = _CONSUMABLE_TYPE_TABLES["hard" if is_hard else "normal"]
	var table: Array = tables.get(chapter, tables.get(1, []))
	var roll := _rng.randf()
	var entry: Dictionary = {}
	for e in table:
		if roll <= e["threshold"]:
			entry = e
			break
	if entry.is_empty():
		entry = table[table.size() - 1]

	var item := ItemData.new()
	item.id = entry["id"]
	item.display_name = entry["name"]
	item.item_type = GameEnums.ItemType.CONSUMABLE
	item.width = 1
	item.height = 1 if item.id != &"flashlight" and item.id != &"torch" else 2
	return item


func _roll_combat_relic_count(chapter: int, roll: float) -> int:
	var table: Array = _RELIC_COUNT_TABLES.get(chapter, _RELIC_COUNT_TABLES.get(1, []))
	return _roll_from_table(roll, table)


func _roll_from_table(roll: float, table: Array) -> int:
	for entry in table:
		if roll <= entry["threshold"]:
			return entry["value"]
	return table[table.size() - 1]["value"]


# --- Probability Tables ---

const _GOLD_TABLES: Dictionary = {
	"normal": {
		1: [{"threshold": 0.17, "value": 3}, {"threshold": 0.65, "value": 4}, {"threshold": 0.85, "value": 5}, {"threshold": 1.00, "value": 6}],
		2: [{"threshold": 0.09, "value": 4}, {"threshold": 0.35, "value": 5}, {"threshold": 0.78, "value": 6}, {"threshold": 0.92, "value": 7}, {"threshold": 0.99, "value": 8}, {"threshold": 1.00, "value": 9}],
		3: [{"threshold": 0.22, "value": 6}, {"threshold": 0.60, "value": 7}, {"threshold": 0.85, "value": 8}, {"threshold": 0.97, "value": 9}, {"threshold": 1.00, "value": 10}],
		4: [{"threshold": 0.22, "value": 8}, {"threshold": 0.48, "value": 9}, {"threshold": 0.68, "value": 10}, {"threshold": 0.86, "value": 11}, {"threshold": 0.96, "value": 12}, {"threshold": 1.00, "value": 13}],
		5: [{"threshold": 0.14, "value": 10}, {"threshold": 0.36, "value": 11}, {"threshold": 0.70, "value": 12}, {"threshold": 0.91, "value": 13}, {"threshold": 0.98, "value": 14}, {"threshold": 1.00, "value": 15}],
	},
	"hard": {
		1: [{"threshold": 0.17, "value": 7}, {"threshold": 0.65, "value": 8}, {"threshold": 0.85, "value": 9}, {"threshold": 0.97, "value": 10}, {"threshold": 1.00, "value": 11}],
		2: [{"threshold": 0.09, "value": 8}, {"threshold": 0.35, "value": 9}, {"threshold": 0.78, "value": 10}, {"threshold": 0.92, "value": 11}, {"threshold": 0.99, "value": 12}, {"threshold": 1.00, "value": 13}],
		3: [{"threshold": 0.17, "value": 12}, {"threshold": 0.65, "value": 13}, {"threshold": 0.85, "value": 14}, {"threshold": 0.97, "value": 15}, {"threshold": 1.00, "value": 16}],
		4: [{"threshold": 0.22, "value": 14}, {"threshold": 0.48, "value": 15}, {"threshold": 0.68, "value": 16}, {"threshold": 0.86, "value": 17}, {"threshold": 1.00, "value": 18}],
		5: [{"threshold": 0.14, "value": 14}, {"threshold": 0.36, "value": 15}, {"threshold": 0.70, "value": 16}, {"threshold": 0.91, "value": 17}, {"threshold": 0.98, "value": 18}, {"threshold": 1.00, "value": 20}],
	},
}

const _CONSUMABLE_COUNT_TABLES: Dictionary = {
	"normal": {
		1: [{"threshold": 0.50, "value": 1}, {"threshold": 0.90, "value": 2}, {"threshold": 1.00, "value": 3}],
		2: [{"threshold": 0.30, "value": 1}, {"threshold": 0.85, "value": 2}, {"threshold": 1.00, "value": 3}],
		3: [{"threshold": 0.43, "value": 2}, {"threshold": 0.83, "value": 3}, {"threshold": 1.00, "value": 4}],
		4: [{"threshold": 0.20, "value": 2}, {"threshold": 0.57, "value": 3}, {"threshold": 0.95, "value": 4}, {"threshold": 1.00, "value": 5}],
		5: [{"threshold": 0.15, "value": 2}, {"threshold": 0.50, "value": 3}, {"threshold": 0.85, "value": 4}, {"threshold": 1.00, "value": 5}],
	},
	"hard": {
		1: [{"threshold": 0.35, "value": 1}, {"threshold": 0.80, "value": 2}, {"threshold": 1.00, "value": 3}],
		2: [{"threshold": 0.06, "value": 1}, {"threshold": 0.51, "value": 2}, {"threshold": 0.92, "value": 3}, {"threshold": 1.00, "value": 4}],
		3: [{"threshold": 0.30, "value": 2}, {"threshold": 0.75, "value": 3}, {"threshold": 1.00, "value": 4}],
		4: [{"threshold": 0.20, "value": 2}, {"threshold": 0.55, "value": 3}, {"threshold": 0.95, "value": 4}, {"threshold": 1.00, "value": 5}],
		5: [{"threshold": 0.25, "value": 3}, {"threshold": 0.60, "value": 4}, {"threshold": 0.90, "value": 5}, {"threshold": 1.00, "value": 6}],
	},
}

const _CONSUMABLE_TYPE_TABLES: Dictionary = {
	"normal": {
		1: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.19},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.42},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.77},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.87},
			{"id": &"torch",        "name": "火把",   "threshold": 0.96},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
		2: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.18},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.38},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.70},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.86},
			{"id": &"torch",        "name": "火把",   "threshold": 0.96},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
		3: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.16},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.36},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.68},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.84},
			{"id": &"torch",        "name": "火把",   "threshold": 0.96},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
		4: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.16},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.38},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.69},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.85},
			{"id": &"torch",        "name": "火把",   "threshold": 0.95},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
		5: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.18},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.42},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.68},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.82},
			{"id": &"torch",        "name": "火把",   "threshold": 0.94},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
	},
	"hard": {
		1: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.16},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.38},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.70},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.84},
			{"id": &"torch",        "name": "火把",   "threshold": 0.95},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
		2: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.11},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.31},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.63},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.80},
			{"id": &"torch",        "name": "火把",   "threshold": 0.94},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
		3: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.12},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.34},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.64},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.80},
			{"id": &"torch",        "name": "火把",   "threshold": 0.94},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
		4: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.11},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.33},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.63},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.81},
			{"id": &"torch",        "name": "火把",   "threshold": 0.94},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
		5: [
			{"id": &"stone",        "name": "石块",   "threshold": 0.10},
			{"id": &"whetstone",    "name": "磨刀石",  "threshold": 0.32},
			{"id": &"energy_drink", "name": "能量饮料", "threshold": 0.60},
			{"id": &"flashlight",   "name": "手电筒",  "threshold": 0.78},
			{"id": &"torch",        "name": "火把",   "threshold": 0.93},
			{"id": &"safe_house_key","name": "安全屋房卡","threshold": 1.00},
		],
	},
}

const _RELIC_COUNT_TABLES: Dictionary = {
	1: [{"threshold": 0.80, "value": 0}, {"threshold": 1.00, "value": 1}],
	2: [{"threshold": 0.70, "value": 0}, {"threshold": 1.00, "value": 1}],
	3: [{"threshold": 0.60, "value": 0}, {"threshold": 1.00, "value": 1}],
	4: [{"threshold": 0.55, "value": 0}, {"threshold": 1.00, "value": 1}],
	5: [{"threshold": 0.48, "value": 0}, {"threshold": 0.98, "value": 1}, {"threshold": 1.00, "value": 2}],
}

const _NORMAL_ENEMY_STAT_TABLES: Dictionary = {
	1: [
		{"threshold": 0.37, "hp": 11, "attack": 3},
		{"threshold": 0.59, "hp": 14, "attack": 2},
		{"threshold": 0.90, "hp": 17, "attack": 1},
		{"threshold": 1.00, "hp": 19, "attack": 1},
	],
	2: [
		{"threshold": 0.23, "hp": 17, "attack": 5},
		{"threshold": 0.41, "hp": 21, "attack": 4},
		{"threshold": 0.72, "hp": 27, "attack": 3},
		{"threshold": 0.90, "hp": 31, "attack": 2},
		{"threshold": 1.00, "hp": 38, "attack": 1},
	],
	3: [
		{"threshold": 0.24, "hp": 22, "attack": 6},
		{"threshold": 0.43, "hp": 29, "attack": 5},
		{"threshold": 0.69, "hp": 34, "attack": 4},
		{"threshold": 0.89, "hp": 41, "attack": 3},
		{"threshold": 1.00, "hp": 49, "attack": 2},
	],
	4: [
		{"threshold": 0.21, "hp": 26, "attack": 8},
		{"threshold": 0.44, "hp": 31, "attack": 6},
		{"threshold": 0.62, "hp": 39, "attack": 4},
		{"threshold": 0.78, "hp": 52, "attack": 3},
		{"threshold": 1.00, "hp": 66, "attack": 2},
	],
	5: [
		{"threshold": 0.19, "hp": 30, "attack": 10},
		{"threshold": 0.42, "hp": 39, "attack": 7},
		{"threshold": 0.69, "hp": 45, "attack": 5},
		{"threshold": 0.89, "hp": 52, "attack": 3},
		{"threshold": 1.00, "hp": 81, "attack": 1},
	],
}

const _HARD_DEBUFF_WEIGHT_TABLES: Dictionary = {
	0: [
		{"threshold": 0.40, "debuff": GameEnums.DebuffType.COWARDICE},
		{"threshold": 0.60, "debuff": GameEnums.DebuffType.WEAKNESS},
		{"threshold": 0.70, "debuff": GameEnums.DebuffType.BLEEDING},
		{"threshold": 0.80, "debuff": GameEnums.DebuffType.TREMBLING},
		{"threshold": 0.90, "debuff": GameEnums.DebuffType.MADNESS},
		{"threshold": 0.97, "debuff": GameEnums.DebuffType.DELIRIUM},
		{"threshold": 1.00, "debuff": GameEnums.DebuffType.DESPAIR},
	],
	1: [
		{"threshold": 0.30, "debuff": GameEnums.DebuffType.COWARDICE},
		{"threshold": 0.50, "debuff": GameEnums.DebuffType.WEAKNESS},
		{"threshold": 0.65, "debuff": GameEnums.DebuffType.BLEEDING},
		{"threshold": 0.77, "debuff": GameEnums.DebuffType.TREMBLING},
		{"threshold": 0.87, "debuff": GameEnums.DebuffType.MADNESS},
		{"threshold": 0.92, "debuff": GameEnums.DebuffType.DELIRIUM},
		{"threshold": 0.97, "debuff": GameEnums.DebuffType.DESPAIR},
		{"threshold": 0.99, "debuff": GameEnums.DebuffType.DULLNESS},
		{"threshold": 1.00, "debuff": GameEnums.DebuffType.HESITATION},
	],
	2: [
		{"threshold": 0.15, "debuff": GameEnums.DebuffType.COWARDICE},
		{"threshold": 0.35, "debuff": GameEnums.DebuffType.WEAKNESS},
		{"threshold": 0.55, "debuff": GameEnums.DebuffType.BLEEDING},
		{"threshold": 0.70, "debuff": GameEnums.DebuffType.TREMBLING},
		{"threshold": 0.85, "debuff": GameEnums.DebuffType.MADNESS},
		{"threshold": 0.90, "debuff": GameEnums.DebuffType.DELIRIUM},
		{"threshold": 0.97, "debuff": GameEnums.DebuffType.DESPAIR},
		{"threshold": 0.99, "debuff": GameEnums.DebuffType.DULLNESS},
		{"threshold": 1.00, "debuff": GameEnums.DebuffType.HESITATION},
	],
	3: [
		{"threshold": 0.10, "debuff": GameEnums.DebuffType.COWARDICE},
		{"threshold": 0.30, "debuff": GameEnums.DebuffType.WEAKNESS},
		{"threshold": 0.50, "debuff": GameEnums.DebuffType.BLEEDING},
		{"threshold": 0.63, "debuff": GameEnums.DebuffType.TREMBLING},
		{"threshold": 0.73, "debuff": GameEnums.DebuffType.MADNESS},
		{"threshold": 0.83, "debuff": GameEnums.DebuffType.DELIRIUM},
		{"threshold": 0.93, "debuff": GameEnums.DebuffType.DESPAIR},
		{"threshold": 0.97, "debuff": GameEnums.DebuffType.DULLNESS},
		{"threshold": 1.00, "debuff": GameEnums.DebuffType.HESITATION},
	],
	4: [
		{"threshold": 0.03, "debuff": GameEnums.DebuffType.WEAKNESS},
		{"threshold": 0.28, "debuff": GameEnums.DebuffType.BLEEDING},
		{"threshold": 0.48, "debuff": GameEnums.DebuffType.TREMBLING},
		{"threshold": 0.58, "debuff": GameEnums.DebuffType.MADNESS},
		{"threshold": 0.73, "debuff": GameEnums.DebuffType.DELIRIUM},
		{"threshold": 0.88, "debuff": GameEnums.DebuffType.DESPAIR},
		{"threshold": 0.95, "debuff": GameEnums.DebuffType.DULLNESS},
		{"threshold": 1.00, "debuff": GameEnums.DebuffType.HESITATION},
	],
}

const _HARD_ENEMY_STAT_TABLES: Dictionary = {
	1: [
		{"threshold": 0.22, "hp": 16, "attack": 4, "mechanic": &"double_attack_turn2"},
		{"threshold": 0.49, "hp": 28, "attack": 3, "mechanic": &""},
		{"threshold": 0.80, "hp": 33, "attack": 2, "mechanic": &"hp_threshold_attack_up"},
		{"threshold": 1.00, "hp": 41, "attack": 1, "mechanic": &"hp_threshold_heal_once"},
	],
	2: [
		{"threshold": 0.23, "hp": 23, "attack": 6, "mechanic": &"double_attack_turn2"},
		{"threshold": 0.41, "hp": 41, "attack": 5, "mechanic": &""},
		{"threshold": 0.72, "hp": 46, "attack": 3, "mechanic": &"hp_threshold_damage_reduction"},
		{"threshold": 0.90, "hp": 51, "attack": 2, "mechanic": &"hp_threshold_attack_up"},
		{"threshold": 1.00, "hp": 62, "attack": 1, "mechanic": &"hp_threshold_heal_once"},
	],
	3: [
		{"threshold": 0.23, "hp": 28, "attack": 7, "mechanic": &"double_attack_turn3"},
		{"threshold": 0.42, "hp": 46, "attack": 6, "mechanic": &""},
		{"threshold": 0.68, "hp": 53, "attack": 4, "mechanic": &"hp_threshold_damage_reduction"},
		{"threshold": 0.88, "hp": 60, "attack": 3, "mechanic": &"hp_threshold_attack_up"},
		{"threshold": 1.00, "hp": 82, "attack": 1, "mechanic": &"hp_threshold_heal_once"},
	],
	4: [
		{"threshold": 0.19, "hp": 32, "attack": 8, "mechanic": &"double_attack_turn3"},
		{"threshold": 0.42, "hp": 51, "attack": 7, "mechanic": &""},
		{"threshold": 0.62, "hp": 57, "attack": 4, "mechanic": &"hp_threshold_damage_reduction"},
		{"threshold": 0.78, "hp": 65, "attack": 3, "mechanic": &"hp_threshold_attack_up"},
		{"threshold": 1.00, "hp": 91, "attack": 1, "mechanic": &"hp_threshold_heal_once"},
	],
	5: [
		{"threshold": 0.19, "hp": 40, "attack": 11, "mechanic": &"double_attack_turn4"},
		{"threshold": 0.42, "hp": 62, "attack": 9,  "mechanic": &""},
		{"threshold": 0.69, "hp": 71, "attack": 6,  "mechanic": &"hp_threshold_damage_reduction"},
		{"threshold": 0.89, "hp": 82, "attack": 3,  "mechanic": &"hp_threshold_attack_up"},
		{"threshold": 1.00, "hp": 111, "attack": 1, "mechanic": &"hp_threshold_heal_once"},
	],
}


func generate_enemy_stats(enemy_type: GameEnums.EnemyType, chapter: int) -> Dictionary:
	var clamped_chapter := clampi(chapter, 1, 5)
	var roll := _rng.randf()
	var tables: Array
	match enemy_type:
		GameEnums.EnemyType.NORMAL:
			tables = _NORMAL_ENEMY_STAT_TABLES[clamped_chapter]
		GameEnums.EnemyType.HARD:
			tables = _HARD_ENEMY_STAT_TABLES[clamped_chapter]
		_:
			return {"hp": 14, "attack": 4, "mechanic": &""}

	for entry in tables:
		if roll <= entry.threshold:
			return {
				"hp": entry.hp,
				"attack": entry.attack,
				"mechanic": entry.get("mechanic", &""),
			}
	return {"hp": 14, "attack": 4, "mechanic": &""}


func generate_hard_combat_debuff(chapter: int, difficulty_level: int = 0) -> GameEnums.DebuffType:
	var clamped_level := clampi(difficulty_level, 0, 4)
	var table: Array = _HARD_DEBUFF_WEIGHT_TABLES.get(clamped_level, _HARD_DEBUFF_WEIGHT_TABLES.get(0, []))
	var roll := _rng.randf()
	for entry in table:
		if roll <= entry.threshold:
			return entry.debuff as GameEnums.DebuffType
	return GameEnums.DebuffType.COWARDICE

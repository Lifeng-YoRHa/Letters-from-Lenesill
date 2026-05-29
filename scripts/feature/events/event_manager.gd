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
	box.display_name = "Locked Box"
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

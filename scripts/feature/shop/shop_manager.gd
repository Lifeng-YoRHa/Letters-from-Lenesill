class_name ShopManager
extends RefCounted

signal item_purchased(item: ItemData, price: int)
signal item_sold(item: ItemData, price: int)
signal stock_depleted(slot_index: int)

class ShopSlot:
	var item: ItemData
	var quantity: int
	var buy_price: int
	var sell_price: int
	var is_fixed: bool = false

	func _init(p_item: ItemData, p_qty: int, p_buy: int, p_sell: int = 0) -> void:
		item = p_item
		quantity = p_qty
		buy_price = p_buy
		sell_price = p_sell

var slots: Array[ShopSlot] = []
var current_node_id: StringName = &""
var _stock_by_node: Dictionary = {}
var current_chapter: int = 1
var _rng: RandomNumberGenerator
var _relic_handler: RelicHandler
var _backpack_manager: BackpackManager


func initialize(rng: RandomNumberGenerator, relic_handler: RelicHandler, backpack_manager: BackpackManager) -> void:
	_rng = rng
	_relic_handler = relic_handler
	_backpack_manager = backpack_manager


const _WEAPON_DEFINITIONS: Array[Dictionary] = [
	{"id": &"fruit_knife",          "name": "水果刀",       "attack": 6,  "durability": 4,  "size": Vector2i(1, 2), "chapter": 1, "trait": &""},
	{"id": &"kitchen_knife",        "name": "菜刀",         "attack": 9,  "durability": 5,  "size": Vector2i(2, 2), "chapter": 1, "trait": &""},
	{"id": &"decorative_katana",   "name": "装饰用武士刀",  "attack": 15, "durability": 3,  "size": Vector2i(1, 5), "chapter": 1, "trait": &""},
	{"id": &"iron_rod",            "name": "铁棍",         "attack": 8,  "durability": 8,  "size": Vector2i(1, 4), "chapter": 2, "trait": &""},
	{"id": &"fire_extinguisher",  "name": "灭火器",       "attack": 7,  "durability": 9,  "size": Vector2i(2, 3), "chapter": 2, "trait": &"extinguisher_boost"},
	{"id": &"mason_hammer",        "name": "石工锤",       "attack": 18, "durability": 8,  "size": Vector2i(2, 5), "chapter": 3, "trait": &"hammer_heavy"},
	{"id": &"diesel_chainsaw",    "name": "柴油电锯",     "attack": 20, "durability": 7,  "size": Vector2i(3, 4), "chapter": 3, "trait": &"chainsaw_irreparable"},
	{"id": &"crowbar",            "name": "撬棍",         "attack": 12, "durability": 9,  "size": Vector2i(1, 5), "chapter": 4, "trait": &""},
	{"id": &"expandable_baton",  "name": "甩棍",         "attack": 13, "durability": 10, "size": Vector2i(1, 4), "chapter": 4, "trait": &"baton_light"},
	{"id": &"military_dagger",   "name": "军用匕首",     "attack": 18, "durability": 10, "size": Vector2i(1, 3), "chapter": 4, "trait": &""},
]


func generate_stock(chapter: int, has_lost_letter_quest: bool = false, lost_letter_price: int = 0) -> void:
	current_chapter = chapter
	slots = []

	# Fixed slots 1-3: Energy Drink, Stone, Whetstone
	var energy_drink := _create_consumable(&"energy_drink", "能量饮料", 1, 1, GameEnums.ConsumableEffect.RESTORE_STAMINA)
	var stone := _create_consumable(&"stone", "石块", 1, 1, GameEnums.ConsumableEffect.FLEE_COMBAT)
	var whetstone := _create_consumable(&"whetstone", "磨刀石", 1, 1, GameEnums.ConsumableEffect.RESTORE_WEAPON_DURABILITY)

	var ed_price := _roll_price(chapter, [3, 4], [4, 5], [5, 6], [6, 7], [7, 8])
	var stone_price := _roll_price(chapter, [2, 3], [3, 4], [4, 5], [5, 6], [6, 7])
	var whet_price := _roll_price(chapter, [3, 4], [4, 5], [5, 6], [6, 7], [7, 8])

	var ed_qty := _rng.randi_range(3, 6)
	var stone_qty := _rng.randi_range(1, 4)
	var whet_qty := _rng.randi_range(1, 4)

	var slot1 := ShopSlot.new(energy_drink, ed_qty, ed_price, 2)
	slot1.is_fixed = true
	slots.append(slot1)

	var slot2 := ShopSlot.new(stone, stone_qty, stone_price, 1)
	slot2.is_fixed = true
	slots.append(slot2)

	var slot3 := ShopSlot.new(whetstone, whet_qty, whet_price, 2)
	slot3.is_fixed = true
	slots.append(slot3)

	# Variable slot 4: Torch (60%) / Relic (30%) / Weapon (10%)
	var slot4 := _generate_variable_slot_4(chapter)
	slots.append(slot4)

	# Variable slot 5: Flashlight (60%) / Safe House Key (30%) / Backpack (10%)
	var slot5 := _generate_variable_slot_5(chapter)
	slots.append(slot5)

	# Quest slot 6: Lost Letter (if applicable)
	if has_lost_letter_quest:
		var lost_letter := ItemData.new()
		lost_letter.id = &"lost_letter"
		lost_letter.display_name = "遗失信件"
		lost_letter.item_type = GameEnums.ItemType.CONSUMABLE
		lost_letter.width = 1
		lost_letter.height = 1
		var quest_slot := ShopSlot.new(lost_letter, 1, lost_letter_price, 0)
		quest_slot.is_fixed = true
		slots.append(quest_slot)


func ensure_stock_for_node(node_id: StringName, chapter: int, has_lost_letter_quest: bool = false, lost_letter_price: int = 0) -> void:
	current_node_id = node_id
	if _stock_by_node.has(node_id):
		slots = _stock_by_node[node_id]
		return
	generate_stock(chapter, has_lost_letter_quest, lost_letter_price)
	_stock_by_node[node_id] = slots


func _create_consumable(id: StringName, name: String, w: int, h: int, effect: GameEnums.ConsumableEffect) -> ItemData:
	var item := ItemData.new()
	item.id = id
	item.display_name = name
	item.item_type = GameEnums.ItemType.CONSUMABLE
	item.width = w
	item.height = h
	return item


func _roll_price(chapter: int, c1: Array, c2: Array, c3: Array, c4: Array, c5: Array) -> int:
	var range_arr: Array
	match chapter:
		1: range_arr = c1
		2: range_arr = c2
		3: range_arr = c3
		4: range_arr = c4
		_: range_arr = c5
	if range_arr.size() == 1:
		return range_arr[0]
	return _rng.randi_range(range_arr[0], range_arr[1])


func _generate_variable_slot_4(chapter: int) -> ShopSlot:
	var roll := _rng.randf()
	if roll < 0.60:
		# Torch
		var torch := _create_consumable(&"torch", "火把", 1, 2, GameEnums.ConsumableEffect.DEAL_DAMAGE)
		torch.rotatable = true
		var qty := _rng.randi_range(1, 2)
		var price := _roll_price(chapter, [6, 7], [7, 8], [9, 10], [10, 11], [12, 13])
		return ShopSlot.new(torch, qty, price, 4)
	elif roll < 0.90:
		# Relic placeholder
		var relic := ItemData.new()
		relic.id = &"relic_placeholder"
		relic.display_name = "遗物"
		relic.item_type = GameEnums.ItemType.RELIC
		var price := _rng.randi_range(25, 30) + (chapter - 1) * 2
		return ShopSlot.new(relic, 1, price, 12)
	else:
		# Weapon
		var weapon_item := _generate_weapon_for_shop(chapter)
		if weapon_item != null:
			var price := 20 + chapter * 6 + weapon_item.weapon_data.attack
			return ShopSlot.new(weapon_item, 1, price, weapon_item.weapon_data.attack)
		# Fallback: no available weapon, roll torch instead
		var torch := _create_consumable(&"torch", "火把", 1, 2, GameEnums.ConsumableEffect.DEAL_DAMAGE)
		torch.rotatable = true
		var qty := _rng.randi_range(1, 2)
		var t_price := _roll_price(chapter, [6, 7], [7, 8], [9, 10], [10, 11], [12, 13])
		return ShopSlot.new(torch, qty, t_price, 4)


func _generate_weapon_for_shop(chapter: int) -> ItemData:
	var candidates: Array[Dictionary] = []
	for def in _WEAPON_DEFINITIONS:
		if def["chapter"] <= chapter:
			if _backpack_manager != null and not _backpack_manager.has_weapon_in_adventure(def["id"]):
				candidates.append(def)
	if candidates.is_empty():
		return null
	var chosen := candidates[_rng.randi_range(0, candidates.size() - 1)]
	var wdata := WeaponData.new()
	wdata.id = chosen["id"]
	wdata.display_name = chosen["name"]
	wdata.attack = chosen["attack"]
	wdata.max_durability = chosen["durability"]
	wdata.size = chosen["size"]
	wdata.unlock_chapter = chosen["chapter"]
	wdata.special_trait_id = chosen["trait"]
	return _backpack_manager.create_weapon_item(wdata)


func _generate_variable_slot_5(chapter: int) -> ShopSlot:
	var roll := _rng.randf()
	if roll < 0.60:
		# Flashlight
		var flashlight := _create_consumable(&"flashlight", "手电筒", 1, 2, GameEnums.ConsumableEffect.REVEAL_NODES)
		flashlight.rotatable = true
		var qty := _rng.randi_range(1, 2)
		var price := _roll_price(chapter, [5, 6], [6, 7], [8, 9], [9, 10], [10, 11])
		return ShopSlot.new(flashlight, qty, price, 3)
	elif roll < 0.90:
		# Safe House Key
		var key := _create_consumable(&"safe_house_key", "安全屋房卡", 1, 1, GameEnums.ConsumableEffect.OPEN_SAFE_HOUSE)
		var price_range: Array[int] = [12, 13, 14, 15]
		var price: int = price_range[_rng.randi_range(0, price_range.size() - 1)] + (chapter - 1) * 2
		return ShopSlot.new(key, _rng.randi_range(1, 2), price, 8)
	else:
		# Backpack placeholder
		var backpack := ItemData.new()
		backpack.id = &"backpack_placeholder"
		backpack.display_name = "背包"
		backpack.item_type = GameEnums.ItemType.BACKPACK
		var price := 20 + chapter * 4
		return ShopSlot.new(backpack, 1, price, 0)


func get_final_buy_price(slot_index: int) -> int:
	if slot_index < 0 or slot_index >= slots.size():
		return 0
	var price := slots[slot_index].buy_price
	if _relic_handler != null:
		var discount := _relic_handler.get_shop_sell_discount_percent()
		price = int(floor(price * (1.0 - discount)))
	return maxi(price, 1)


func can_purchase(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	var slot := slots[slot_index]
	if slot.quantity <= 0:
		return false
	var price := get_final_buy_price(slot_index)
	if _backpack_manager == null:
		return false
	if _backpack_manager.gold_count < price:
		return false
	return _backpack_manager.can_fit_anywhere(slot.item)


func purchase(slot_index: int) -> bool:
	if not can_purchase(slot_index):
		return false
	var slot := slots[slot_index]
	var price := get_final_buy_price(slot_index)

	_backpack_manager.remove_gold(price)
	var purchased_item: ItemData = slot.item.duplicate()
	_backpack_manager.add_item(purchased_item)
	slot.quantity -= 1

	item_purchased.emit(slot.item, price)
	if slot.quantity <= 0:
		stock_depleted.emit(slot_index)
	return true


func get_sell_price(item: ItemData) -> int:
	match item.item_type:
		GameEnums.ItemType.WEAPON:
			if item.weapon_data == null:
				return 1
			var atk := item.get_weapon_attack()
			var max_dur := item.get_weapon_max_durability()
			var dur_ratio := 0.0 if max_dur <= 0 else float(item.weapon_current_durability) / float(max_dur)
			return atk + int(floor(2.0 * dur_ratio))
		GameEnums.ItemType.RELIC:
			return 12
		GameEnums.ItemType.CONSUMABLE:
			match item.id:
				&"energy_drink": return 2
				&"stone": return 1
				&"whetstone": return 2
				&"torch": return 4
				&"flashlight": return 3
				&"safe_house_key": return 8
				_: return 1
		_:
			return 0


func can_sell(item: ItemData) -> bool:
	if item.item_type == GameEnums.ItemType.BACKPACK:
		return false
	return true


func sell(item: ItemData) -> bool:
	if not can_sell(item):
		return false
	var price := get_sell_price(item)
	if not _backpack_manager.remove_item(item):
		return false
	_backpack_manager.add_gold(price)
	item_sold.emit(item, price)
	return true

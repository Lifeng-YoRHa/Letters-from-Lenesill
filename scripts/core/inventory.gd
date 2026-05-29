class_name Inventory
extends RefCounted

signal gold_changed(new_amount: int, old_amount: int)
signal equipped_weapon_changed(new_weapon: WeaponData, old_weapon: WeaponData)
signal item_added(item: InventoryItem)
signal item_removed(item: InventoryItem)

var equipped_weapon: WeaponData:
	get:
		return _equipped_weapon

var gold: int:
	get:
		return _gold

var _equipped_weapon: WeaponData
var _gold: int = 0
var _items: Array[InventoryItem] = []


func initialize(starting_gold: int) -> void:
	_gold = starting_gold


func add_gold(amount: int) -> int:
	if amount <= 0:
		return 0
	if _gold >= 99:
		return 0
	var old: int = _gold
	var accepted: int = mini(amount, 99 - _gold)
	_gold += accepted
	gold_changed.emit(_gold, old)
	return accepted


func remove_gold(amount: int) -> int:
	if amount <= 0:
		return 0
	var old: int = _gold
	var removed: int = mini(amount, _gold)
	_gold -= removed
	gold_changed.emit(_gold, old)
	return removed


func set_equipped_weapon(weapon: WeaponData) -> void:
	var old: WeaponData = _equipped_weapon
	_equipped_weapon = weapon
	equipped_weapon_changed.emit(weapon, old)


func add_item(item: InventoryItem) -> void:
	_items.append(item)
	item_added.emit(item)


func remove_item(item: InventoryItem) -> void:
	_items.erase(item)
	item_removed.emit(item)


func get_all_items() -> Array[InventoryItem]:
	return _items.duplicate()


func get_pocket_items(pocket_index: int) -> Array[InventoryItem]:
	var result: Array[InventoryItem] = []
	for item in _items:
		if item.pocket_index == pocket_index:
			result.append(item)
	return result


func get_backpack_items() -> Array[InventoryItem]:
	var result: Array[InventoryItem] = []
	for item in _items:
		if item.pocket_index == -1:
			result.append(item)
	return result

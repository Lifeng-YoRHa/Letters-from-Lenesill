class_name BackpackManager
extends RefCounted

signal item_added(item: ItemData)
signal item_removed(item: ItemData)
signal weapon_equipped(weapon: ItemData)
signal weapon_unequipped(weapon: ItemData)
signal backpack_changed(new_backpack_type: StringName)
signal gold_changed(new_amount: int)

var primary_grid: BackpackGrid
var secondary_grids: Array[BackpackGrid] = []
var pocket_a: BackpackGrid
var pocket_b: BackpackGrid

var equipped_weapon: ItemData = null
var gold_count: int = 0
var current_backpack_type: StringName = &"satchel"

const MAX_GOLD: int = 99


func initialize() -> void:
	_setup_backpack(current_backpack_type)
	_setup_pockets()


func _setup_backpack(type: StringName) -> void:
	match type:
		&"satchel":
			primary_grid = _create_grid(3, 4)
			secondary_grids = [_create_grid(1, 2)]
		&"student_backpack":
			primary_grid = _create_grid(4, 5)
			secondary_grids = [_create_grid(1, 2), _create_grid(1, 2)]
		&"travel_backpack":
			primary_grid = _create_grid(5, 6)
			secondary_grids = [_create_grid(1, 3), _create_grid(1, 3)]
		&"padlocked_laptop_bag":
			primary_grid = _create_grid(6, 4)
			secondary_grids = [_create_grid(2, 2), _create_grid(2, 2), _create_grid(2, 2)]
		&"marching_backpack":
			primary_grid = _create_grid(7, 6)
			secondary_grids = [_create_grid(1, 4), _create_grid(1, 4)]
		&"oversized_backpack":
			primary_grid = _create_grid(8, 7)
			secondary_grids = [_create_grid(1, 5), _create_grid(1, 5)]
		_:
			primary_grid = _create_grid(3, 4)
			secondary_grids = [_create_grid(1, 2)]


func _create_grid(width: int, height: int) -> BackpackGrid:
	var grid := BackpackGrid.new()
	grid.initialize(width, height)
	return grid


func _setup_pockets() -> void:
	pocket_a = _create_grid(1, 2)
	pocket_b = _create_grid(1, 2)


func get_all_grids() -> Array[BackpackGrid]:
	var result: Array[BackpackGrid] = [primary_grid]
	result.append_array(secondary_grids)
	return result


func get_all_storage_grids() -> Array[BackpackGrid]:
	var result := get_all_grids()
	result.append(pocket_a)
	result.append(pocket_b)
	return result


func can_fit_anywhere(item: ItemData) -> bool:
	for grid in get_all_storage_grids():
		if not grid.find_placement(item).is_empty():
			return true
	return false


func add_item(item: ItemData) -> bool:
	if item.item_type == GameEnums.ItemType.WEAPON and equipped_weapon == null:
		equipped_weapon = item
		weapon_equipped.emit(item)
		return true

	for grid in get_all_storage_grids():
		var placement := grid.find_placement(item)
		if not placement.is_empty():
			grid.place(item, placement.x, placement.y, placement.rotated)
			item_added.emit(item)
			return true
	return false


func remove_item(item: ItemData) -> bool:
	if equipped_weapon == item:
		equipped_weapon = null
		weapon_unequipped.emit(item)
		return true

	for grid in get_all_storage_grids():
		if grid.remove(item):
			item_removed.emit(item)
			return true
	return false


func equip_weapon(weapon: ItemData) -> bool:
	if weapon.item_type != GameEnums.ItemType.WEAPON:
		return false
	if equipped_weapon != null:
		if not unequip_weapon():
			return false
	equipped_weapon = weapon
	remove_item(weapon)
	weapon_equipped.emit(weapon)
	return true


func unequip_weapon() -> bool:
	if equipped_weapon == null:
		return false
	if not can_fit_anywhere(equipped_weapon):
		return false
	var weapon := equipped_weapon
	equipped_weapon = null
	weapon_unequipped.emit(weapon)
	add_item(weapon)
	return true


func add_gold(amount: int) -> int:
	if gold_count >= MAX_GOLD:
		return 0
	var actual := mini(amount, MAX_GOLD - gold_count)
	gold_count += actual
	gold_changed.emit(gold_count)
	return actual


func remove_gold(amount: int) -> int:
	var actual := mini(amount, gold_count)
	gold_count -= actual
	gold_changed.emit(gold_count)
	return actual


func get_total_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	var seen := {}
	for grid in get_all_storage_grids():
		for item in grid.get_items():
			if not seen.has(item):
				seen[item] = true
				result.append(item)
	return result


func swap_backpack(new_type: StringName) -> Array[ItemData]:
	var old_items := get_total_items()
	if equipped_weapon != null:
		old_items.append(equipped_weapon)

	current_backpack_type = new_type
	_setup_backpack(new_type)
	backpack_changed.emit(new_type)

	var organizer := ItemOrganizer.new()
	var discarded := organizer.auto_arrange(old_items, self)
	return discarded

class_name BackpackGrid
extends RefCounted

var _grid_width: int
var _grid_height: int
var _cells: Array[Array] = []  # 2D array: null = empty, ItemData = occupied
var _item_positions: Dictionary = {}  # ItemData -> {x, y, rotated}


func initialize(width: int, height: int) -> void:
	_grid_width = width
	_grid_height = height
	_cells = []
	for y in range(height):
		var row: Array = []
		for x in range(width):
			row.append(null)
		_cells.append(row)
	_item_positions.clear()


func can_fit(item: ItemData, x: int, y: int, rotated: bool = false) -> bool:
	var dims := item.get_dimensions(rotated)
	if x < 0 or y < 0 or x + dims.x > _grid_width or y + dims.y > _grid_height:
		return false
	for dy in range(dims.y):
		for dx in range(dims.x):
			if _cells[y + dy][x + dx] != null:
				return false
	return true


func place(item: ItemData, x: int, y: int, rotated: bool = false) -> bool:
	if not can_fit(item, x, y, rotated):
		return false
	var dims := item.get_dimensions(rotated)
	for dy in range(dims.y):
		for dx in range(dims.x):
			_cells[y + dy][x + dx] = item
	_item_positions[item] = {"x": x, "y": y, "rotated": rotated}
	return true


func remove(item: ItemData) -> bool:
	var pos = _item_positions.get(item)
	if pos == null:
		return false
	var dims := item.get_dimensions(pos.rotated)
	for dy in range(dims.y):
		for dx in range(dims.x):
			_cells[pos.y + dy][pos.x + dx] = null
	_item_positions.erase(item)
	return true


func find_placement(item: ItemData) -> Dictionary:
	for y in range(_grid_height):
		for x in range(_grid_width):
			if can_fit(item, x, y, false):
				return {"x": x, "y": y, "rotated": false}
			if item.rotatable and can_fit(item, x, y, true):
				return {"x": x, "y": y, "rotated": true}
	return {}


func get_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	var seen := {}
	for row in _cells:
		for cell in row:
			if cell is ItemData and not seen.has(cell):
				seen[cell] = true
				result.append(cell)
	return result


func is_empty() -> bool:
	return _item_positions.is_empty()


func get_capacity() -> int:
	return _grid_width * _grid_height


func get_used_cells() -> int:
	var count := 0
	for row in _cells:
		for cell in row:
			if cell != null:
				count += 1
	return count

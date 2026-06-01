class_name ItemOrganizer
extends RefCounted

const _PRIORITY_ORDER: Array[StringName] = [
	&"lost_letter",
	&"survivors_letter",
	# Gold is handled separately
	&"weapon",          # equipped weapon if not currently held
	&"relic",
	&"password_box",
	&"safe_house_key",
	&"torch",
	&"flashlight",
	# Other consumables fallback
]


func auto_arrange(items: Array[ItemData], backpack_manager: BackpackManager) -> Array[ItemData]:
	var filtered: Array[ItemData] = []
	for item in items:
		if item.id != &"gold":
			filtered.append(item)
	var sorted := _sort_by_priority(filtered)
	var discarded: Array[ItemData] = []

	for item in sorted:
		var placed := false
		for grid in backpack_manager.get_all_storage_grids():
			var pos := _find_placement_in_grid(grid, item)
			if not pos.is_empty():
				grid.place(item, pos.x, pos.y, pos.rotated)
				placed = true
				break
		if not placed:
			discarded.append(item)

	return discarded


func _sort_by_priority(items: Array[ItemData]) -> Array[ItemData]:
	var scored: Array = []
	for item in items:
		var score := _get_priority_score(item)
		scored.append({"item": item, "score": score})

	scored.sort_custom(func(a, b): return a.score < b.score)

	var result: Array[ItemData] = []
	for entry in scored:
		result.append(entry.item)
	return result


func _get_priority_score(item: ItemData) -> int:
	var idx := _PRIORITY_ORDER.find(item.id)
	if idx >= 0:
		return idx

	match item.item_type:
		GameEnums.ItemType.RELIC:
			return _PRIORITY_ORDER.find(&"relic")
		GameEnums.ItemType.WEAPON:
			return _PRIORITY_ORDER.find(&"weapon")
		GameEnums.ItemType.CONSUMABLE:
			return _PRIORITY_ORDER.size() + 1
		GameEnums.ItemType.BACKPACK:
			return _PRIORITY_ORDER.size() + 2
		_:
			return _PRIORITY_ORDER.size() + 3


func _find_placement_in_grid(grid: BackpackGrid, item: ItemData) -> Dictionary:
	return grid.find_placement(item)

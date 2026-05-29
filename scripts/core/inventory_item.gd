class_name InventoryItem
extends RefCounted

var item_id: StringName
var display_name: String
var item_type: GameEnums.ItemType
var size: Vector2i
var is_rotatable: bool
var position: Vector2i
var is_rotated: bool
var pocket_index: int
var source_data: Resource

func rotate() -> void:
	if not is_rotatable:
		return
	is_rotated = not is_rotated
	size = Vector2i(size.y, size.x)

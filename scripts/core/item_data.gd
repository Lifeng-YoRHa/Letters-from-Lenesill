class_name ItemData
extends Resource

@export var id: StringName
@export var display_name: String
@export var item_type: GameEnums.ItemType
@export var width: int = 1
@export var height: int = 1
@export var rotatable: bool = false
@export var description: String = ""
@export var metadata: Dictionary = {}


func get_dimensions(rotated: bool = false) -> Vector2i:
	if rotated and rotatable:
		return Vector2i(height, width)
	return Vector2i(width, height)


func get_area() -> int:
	return width * height

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
@export var weapon_data: WeaponData = null
@export var weapon_current_durability: int = 0
@export var weapon_current_attack: int = 0


func get_weapon_attack() -> int:
	if weapon_data == null:
		return 0
	var atk: int = weapon_current_attack if weapon_current_attack > 0 else weapon_data.attack
	return maxi(atk, 4)


func get_weapon_max_durability() -> int:
	if weapon_data == null:
		return 0
	return weapon_data.max_durability


func get_weapon_trait_id() -> StringName:
	if weapon_data == null:
		return &""
	return weapon_data.special_trait_id


func is_weapon_broken() -> bool:
	if weapon_data == null:
		return true
	return weapon_current_durability <= 0


func is_chainsaw() -> bool:
	return weapon_data != null and weapon_data.id == &"diesel_chainsaw"


func get_dimensions(rotated: bool = false) -> Vector2i:
	if rotated and rotatable:
		return Vector2i(height, width)
	return Vector2i(width, height)


func get_area() -> int:
	return width * height

class_name ItemInstance
extends RefCounted

enum ItemType {
	ENERGY_DRINK,
	KNIFE,
	XRAY_GLASSES,
	SMALL_MIRROR,
	MINI_EXPLOSIVE,
	PADLOCK,
	THICK_CLOTHES,
}

var item_type: int
var purchase_price: int
var purchase_round: int


func _init(p_type: int, p_price: int, p_round: int) -> void:
	item_type = p_type
	purchase_price = p_price
	purchase_round = p_round

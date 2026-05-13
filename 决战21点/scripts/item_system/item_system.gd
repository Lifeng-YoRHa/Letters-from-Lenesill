class_name ItemSystem
extends Node

## Item inventory and usage system.
## Design reference: design/gdd/item-system.md

signal item_used(item_type: int, effect_data: Dictionary)

const MAX_ITEMS: int = 5

const PRICE_TABLE: Dictionary = {
	ItemInstance.ItemType.ENERGY_DRINK: 70,
	ItemInstance.ItemType.KNIFE: 70,
	ItemInstance.ItemType.XRAY_GLASSES: 150,
	ItemInstance.ItemType.SMALL_MIRROR: 100,
	ItemInstance.ItemType.MINI_EXPLOSIVE: 150,
	ItemInstance.ItemType.PADLOCK: 100,
	ItemInstance.ItemType.THICK_CLOTHES: 60,
}

const EFFECT_VALUES: Dictionary = {
	ItemInstance.ItemType.ENERGY_DRINK: 10,
	ItemInstance.ItemType.KNIFE: 10,
	ItemInstance.ItemType.XRAY_GLASSES: 3,
	ItemInstance.ItemType.THICK_CLOTHES: 10,
}

var inventory: Array[ItemInstance] = []

var _pending_defense: int = 0
var _locked_ai_card: CardInstance = null

var _combat: CombatState
var _chips: ChipEconomy
var _card_data: CardDataModel
var _round_manager: RoundManager


func initialize(
	combat: CombatState,
	chips: ChipEconomy,
	card_data: CardDataModel,
	round_manager: RoundManager,
) -> void:
	_combat = combat
	_chips = chips
	_card_data = card_data
	_round_manager = round_manager


func can_buy_item(item_type: int) -> bool:
	if inventory.size() >= MAX_ITEMS:
		return false
	return _chips.can_afford(PRICE_TABLE.get(item_type, 0))


func buy_item(item_type: int) -> bool:
	if not can_buy_item(item_type):
		return false
	var price: int = PRICE_TABLE[item_type]
	if not _chips.spend_chips(price, ChipEconomy.ChipPurpose.SHOP_PURCHASE):
		return false
	inventory.append(ItemInstance.new(item_type, price, _round_manager.opponent_number))
	return true


func can_use_items() -> bool:
	return _round_manager.current_phase == RoundManager.RoundPhase.SORT


func use_energy_drink(index: int) -> Dictionary:
	if not _validate_use(index, ItemInstance.ItemType.ENERGY_DRINK):
		return {"success": false}
	var item: ItemInstance = inventory[index]
	var overflow: int = _combat.apply_heal(CardEnums.Owner.PLAYER, EFFECT_VALUES[ItemInstance.ItemType.ENERGY_DRINK])
	var result: Dictionary = {"success": true, "item_type": item.item_type, "heal": 10, "overflow": overflow}
	_consume_and_emit(index, result)
	return result


func use_knife(index: int) -> Dictionary:
	if not _validate_use(index, ItemInstance.ItemType.KNIFE):
		return {"success": false}
	var item: ItemInstance = inventory[index]
	_combat.apply_damage(CardEnums.Owner.AI, EFFECT_VALUES[ItemInstance.ItemType.KNIFE])
	var result: Dictionary = {"success": true, "item_type": item.item_type, "damage": 10}
	_consume_and_emit(index, result)
	return result


func use_xray_glasses(index: int) -> Dictionary:
	if not _validate_use(index, ItemInstance.ItemType.XRAY_GLASSES):
		return {"success": false}
	var item: ItemInstance = inventory[index]
	var cards: Array = _round_manager.peek_player_deck(EFFECT_VALUES[ItemInstance.ItemType.XRAY_GLASSES])
	var result: Dictionary = {"success": true, "item_type": item.item_type, "peek_cards": cards}
	_consume_and_emit(index, result)
	return result


func use_small_mirror(item_index: int, ai_card_index: int) -> Dictionary:
	if not _validate_use(item_index, ItemInstance.ItemType.SMALL_MIRROR):
		return {"success": false, "reason": "cannot_use"}
	var ai_hand: Array = _round_manager.ai_hand
	if ai_card_index < 1 or ai_card_index >= ai_hand.size():
		return {"success": false, "reason": "invalid_target"}
	var card: CardInstance = ai_hand[ai_card_index]
	var result: Dictionary = {"success": true, "item_type": ItemInstance.ItemType.SMALL_MIRROR, "revealed_card": card}
	_consume_and_emit(item_index, result)
	return result


func use_mini_explosive(item_index: int, player_card_index: int) -> Dictionary:
	if not _validate_use(item_index, ItemInstance.ItemType.MINI_EXPLOSIVE):
		return {"success": false, "reason": "cannot_use"}
	var remove_result: Dictionary = _round_manager.remove_player_card_from_hand(player_card_index)
	if not remove_result.get("success", false):
		return remove_result
	var result: Dictionary = {"success": true, "item_type": ItemInstance.ItemType.MINI_EXPLOSIVE, "removed_card": remove_result.removed_card}
	_consume_and_emit(item_index, result)
	return result


func use_padlock(item_index: int, ai_card_index: int) -> Dictionary:
	if not _validate_use(item_index, ItemInstance.ItemType.PADLOCK):
		return {"success": false, "reason": "cannot_use"}
	var ai_hand: Array = _round_manager.ai_hand
	if ai_card_index < 0 or ai_card_index >= ai_hand.size():
		return {"success": false, "reason": "invalid_target"}
	_locked_ai_card = ai_hand[ai_card_index]
	var result: Dictionary = {"success": true, "item_type": ItemInstance.ItemType.PADLOCK, "locked_card": _locked_ai_card}
	_consume_and_emit(item_index, result)
	return result


func use_thick_clothes(index: int) -> Dictionary:
	if not _validate_use(index, ItemInstance.ItemType.THICK_CLOTHES):
		return {"success": false}
	var item: ItemInstance = inventory[index]
	var defense_amount: int = EFFECT_VALUES[ItemInstance.ItemType.THICK_CLOTHES]
	_combat.add_defense(CardEnums.Owner.PLAYER, defense_amount)
	var result: Dictionary = {"success": true, "item_type": item.item_type, "defense_added": defense_amount}
	_consume_and_emit(index, result)
	return result


func apply_pending_defense() -> void:
	if _pending_defense > 0:
		_combat.add_defense(CardEnums.Owner.PLAYER, _pending_defense)
		_pending_defense = 0


func unlock_all_ai_cards() -> void:
	_locked_ai_card = null


func get_locked_ai_card() -> CardInstance:
	return _locked_ai_card


func clear_game() -> void:
	inventory.clear()
	_pending_defense = 0
	_locked_ai_card = null


func _validate_use(index: int, expected_type: int) -> bool:
	if index < 0 or index >= inventory.size():
		return false
	if inventory[index].item_type != expected_type:
		return false
	return can_use_items()


func _consume_and_emit(index: int, result: Dictionary) -> void:
	var item_type: int = inventory[index].item_type
	inventory.remove_at(index)
	item_used.emit(item_type, result)

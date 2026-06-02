class_name SafeHouseInterface
extends Control

signal closed
signal notes_requested
signal rest_requested
signal item_taken(item: ItemData, source: StringName)
signal gold_taken(amount: int)
signal weapon_repaired

@onready var _fridge_list: VBoxContainer = %FridgeList
@onready var _piggy_bank_info: Label = %PiggyBankInfo
@onready var _anvil_info: Label = %AnvilInfo
@onready var _rest_button: Button = %RestButton
@onready var _close_button: Button = %CloseButton

var _state: SafeHouseState
var _has_weapon: bool = false


func initialize(state: SafeHouseState, has_weapon: bool) -> void:
	_state = state
	_has_weapon = has_weapon
	_refresh()


func _refresh() -> void:
	_refresh_fridge()
	_refresh_scattered()
	_refresh_piggy_bank()
	_refresh_anvil()


func _clear_container(container: VBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()


func _refresh_fridge() -> void:
	_clear_container(_fridge_list)

	var title := Label.new()
	title.text = "冰箱"
	title.add_theme_font_size_override("font_size", 16)
	_fridge_list.add_child(title)

	if _state.fridge_items.is_empty():
		var empty := Label.new()
		empty.text = "（已清空）"
		_fridge_list.add_child(empty)
		return

	for item in _state.fridge_items:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = item.display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var take_btn := Button.new()
		take_btn.text = "取走"
		take_btn.pressed.connect(func() -> void: _on_take_fridge_item(item))
		row.add_child(take_btn)
		_fridge_list.add_child(row)


func _refresh_scattered() -> void:
	var title := Label.new()
	title.text = "散落物品"
	title.add_theme_font_size_override("font_size", 16)
	_fridge_list.add_child(title)

	if _state.scattered_items.is_empty():
		var empty := Label.new()
		empty.text = "（已清空）"
		_fridge_list.add_child(empty)
		return

	for item in _state.scattered_items:
		var row := HBoxContainer.new()
		var name_label := Label.new()
		name_label.text = item.display_name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var take_btn := Button.new()
		take_btn.text = "取走"
		take_btn.pressed.connect(func() -> void: _on_take_scattered_item(item))
		row.add_child(take_btn)
		_fridge_list.add_child(row)


func _refresh_piggy_bank() -> void:
	_piggy_bank_info.text = "金币: %d" % _state.piggy_bank_gold

	var parent := _piggy_bank_info.get_parent() as VBoxContainer
	if parent == null:
		return

	# Remove old take button if exists
	var old_btn := parent.get_node_or_null("TakeGoldButton")
	if old_btn != null:
		old_btn.queue_free()

	if _state.piggy_bank_gold > 0:
		var take_btn := Button.new()
		take_btn.name = "TakeGoldButton"
		take_btn.text = "取走全部"
		take_btn.pressed.connect(_on_take_gold)
		parent.add_child(take_btn)


func _refresh_anvil() -> void:
	_anvil_info.text = "剩余修理次数: %d" % _state.anvil_uses_remaining

	var parent := _anvil_info.get_parent() as VBoxContainer
	if parent == null:
		return

	var old_btn := parent.get_node_or_null("RepairButton")
	if old_btn != null:
		old_btn.queue_free()

	if _state.anvil_uses_remaining > 0 and _has_weapon:
		var repair_btn := Button.new()
		repair_btn.name = "RepairButton"
		repair_btn.text = "修复武器"
		repair_btn.pressed.connect(_on_repair_weapon)
		parent.add_child(repair_btn)
	elif _state.anvil_uses_remaining > 0 and not _has_weapon:
		var no_weapon := Label.new()
		no_weapon.name = "RepairButton"
		no_weapon.text = "（未装备武器）"
		parent.add_child(no_weapon)


func _on_take_fridge_item(item: ItemData) -> void:
	_state.fridge_items.erase(item)
	item_taken.emit(item, &"fridge")
	_refresh_fridge()


func _on_take_scattered_item(item: ItemData) -> void:
	_state.scattered_items.erase(item)
	item_taken.emit(item, &"scattered")
	_refresh_scattered()


func _on_take_gold() -> void:
	var amount := _state.piggy_bank_gold
	_state.piggy_bank_gold = 0
	gold_taken.emit(amount)
	_refresh_piggy_bank()


func _on_repair_weapon() -> void:
	if _state.anvil_uses_remaining <= 0:
		return
	_state.anvil_uses_remaining -= 1
	weapon_repaired.emit()
	_refresh_anvil()


func _on_close_pressed() -> void:
	closed.emit()


func _on_notes_pressed() -> void:
	notes_requested.emit()


func _ready() -> void:
	if not _rest_button.pressed.is_connected(_on_rest_pressed):
		_rest_button.pressed.connect(_on_rest_pressed)


func _on_rest_pressed() -> void:
	rest_requested.emit()

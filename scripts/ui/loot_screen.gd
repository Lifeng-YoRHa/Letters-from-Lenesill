class_name LootScreen
extends Control

signal loot_taken(gold: int, items: Array[ItemData])
signal loot_abandoned

@onready var _title_label: Label = %TitleLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _item_list: VBoxContainer = %ItemList
@onready var _take_button: Button = %TakeButton
@onready var _abandon_button: Button = %AbandonButton

var _gold: int = 0
var _items: Array[ItemData] = []

func show_loot(gold: int, items: Array[ItemData]) -> void:
	_gold = gold
	_items = items
	visible = true

	_title_label.text = "战斗胜利！"
	_gold_label.text = "获得金币: %d" % gold

	for child in _item_list.get_children():
		child.queue_free()

	for item in items:
		var label := Label.new()
		label.text = item.display_name
		_item_list.add_child(label)

	if items.is_empty() and gold == 0:
		var label := Label.new()
		label.text = "没有获得战利品"
		_item_list.add_child(label)


func _on_take_pressed() -> void:
	loot_taken.emit(_gold, _items)
	visible = false


func _on_abandon_pressed() -> void:
	loot_abandoned.emit()
	visible = false

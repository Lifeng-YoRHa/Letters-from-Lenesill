class_name ShopInterface
extends Control

signal closed

@onready var _close_button: Button = %CloseButton

func initialize(shop_manager: ShopManager) -> void:
	pass  # TODO: populate stock grid and sell panel


func show_placeholder(text: String) -> void:
	var stock := %StockGrid as GridContainer
	if stock != null:
		for child in stock.get_children():
			child.queue_free()
		var label := Label.new()
		label.text = text
		stock.add_child(label)


func _on_close_pressed() -> void:
	closed.emit()

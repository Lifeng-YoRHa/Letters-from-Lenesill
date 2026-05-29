class_name ShopInterface
extends Control

signal closed

@onready var _close_button: Button = %CloseButton

func initialize(shop_manager: ShopManager) -> void:
	pass  # TODO: populate stock grid and sell panel


func _on_close_pressed() -> void:
	closed.emit()

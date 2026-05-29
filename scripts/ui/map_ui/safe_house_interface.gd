class_name SafeHouseInterface
extends Control

signal closed

@onready var _close_button: Button = %CloseButton

func initialize() -> void:
	pass  # TODO: populate fridge, piggy bank, anvil panels


func _on_close_pressed() -> void:
	closed.emit()

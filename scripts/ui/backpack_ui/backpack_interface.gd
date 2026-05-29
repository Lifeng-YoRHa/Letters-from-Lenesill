class_name BackpackInterface
extends Control

signal closed

@onready var _close_button: Button = %CloseButton

func initialize(backpack_manager: BackpackManager) -> void:
	pass  # TODO: populate grid, pockets, weapon/relic slots


func _on_close_pressed() -> void:
	closed.emit()

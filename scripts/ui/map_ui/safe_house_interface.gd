class_name SafeHouseInterface
extends Control

signal closed

@onready var _close_button: Button = %CloseButton

func initialize() -> void:
	pass  # TODO: populate fridge, piggy bank, anvil panels


func show_placeholder(text: String) -> void:
	var content := %ContentContainer as HBoxContainer
	if content != null:
		for child in content.get_children():
			child.queue_free()
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(label)


func _on_close_pressed() -> void:
	closed.emit()

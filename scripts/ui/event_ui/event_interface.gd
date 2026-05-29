class_name EventInterface
extends Control

signal choice_made(choice_index: int)
signal closed

func show_event(event_type: StringName, description: String, choices: Array[String]) -> void:
	pass  # TODO: populate title, description, choice buttons


func show_placeholder(text: String) -> void:
	var desc := %DescriptionLabel as Label
	if desc != null:
		desc.text = text
	var container := %ChoiceContainer as VBoxContainer
	if container != null:
		for child in container.get_children():
			child.queue_free()
		var close_btn := Button.new()
		close_btn.text = "关闭"
		close_btn.pressed.connect(_on_close_pressed)
		container.add_child(close_btn)


func _on_choice_pressed(index: int) -> void:
	choice_made.emit(index)


func _on_close_pressed() -> void:
	closed.emit()

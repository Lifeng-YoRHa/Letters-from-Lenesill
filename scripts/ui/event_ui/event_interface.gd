class_name EventInterface
extends Control

signal choice_made(choice_index: int)
signal closed

func show_event(event_type: StringName, description: String, choices: Array[String]) -> void:
	pass  # TODO: populate title, description, choice buttons


func _on_choice_pressed(index: int) -> void:
	choice_made.emit(index)


func _on_close_pressed() -> void:
	closed.emit()

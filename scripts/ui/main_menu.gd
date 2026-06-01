class_name MainMenu
extends Control

signal new_adventure_pressed
signal continue_pressed
signal survivor_notes_pressed
signal settings_pressed

@onready var _continue_button: Button = %ContinueButton

func set_resume_available(available: bool) -> void:
	_continue_button.visible = available
	_continue_button.disabled = not available


func _has_save_data() -> bool:
	return _continue_button.visible


func _on_new_adventure_pressed() -> void:
	new_adventure_pressed.emit()


func _on_continue_pressed() -> void:
	continue_pressed.emit()


func _on_survivor_notes_pressed() -> void:
	survivor_notes_pressed.emit()


func _on_settings_pressed() -> void:
	settings_pressed.emit()

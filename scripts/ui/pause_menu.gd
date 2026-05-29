class_name PauseMenu
extends Control

signal resume_pressed
signal survivor_notes_pressed
signal settings_pressed
signal return_to_main_menu_pressed

func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_survivor_notes_pressed() -> void:
	survivor_notes_pressed.emit()


func _on_settings_pressed() -> void:
	settings_pressed.emit()


func _on_return_to_main_menu_pressed() -> void:
	return_to_main_menu_pressed.emit()

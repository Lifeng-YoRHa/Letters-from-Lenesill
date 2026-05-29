class_name MainMenu
extends Control

signal new_adventure_pressed
signal continue_pressed
signal survivor_notes_pressed
signal settings_pressed

@onready var _continue_button: Button = %ContinueButton

func _ready() -> void:
	var has_save := _has_save_data()
	_continue_button.visible = has_save
	_continue_button.disabled = not has_save


func _has_save_data() -> bool:
	# TODO: check SaveLoadManager for existing saves
	return false


func _on_new_adventure_pressed() -> void:
	new_adventure_pressed.emit()


func _on_continue_pressed() -> void:
	continue_pressed.emit()


func _on_survivor_notes_pressed() -> void:
	survivor_notes_pressed.emit()


func _on_settings_pressed() -> void:
	settings_pressed.emit()

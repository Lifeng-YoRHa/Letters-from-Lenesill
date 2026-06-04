class_name MainMenu
extends Control

signal new_adventure_pressed
signal continue_pressed
signal survivor_notes_pressed
signal settings_pressed
signal exit_game_pressed
signal difficulty_selected(difficulty_level: int)
signal difficulty_cancelled

@onready var _continue_button: Button = %ContinueButton
@onready var _difficulty_selector: Control = %DifficultySelector

var _current_difficulty_level: int = 0

const _DIFFICULTY_DESCRIPTIONS: Dictionary = {
	0: "难度 0 — 无特殊效果",
	1: "难度 1 — 前两章额外一场艰难战斗",
	2: "难度 2 — 体力上限 -2",
	3: "难度 3 — 开局携带 2 件垃圾",
}


func _ready() -> void:
	if _difficulty_selector != null:
		_difficulty_selector.visible = false
		var left: Button = _difficulty_selector.get_node_or_null("Panel/ButtonsContainer/LeftButton")
		var right: Button = _difficulty_selector.get_node_or_null("Panel/ButtonsContainer/RightButton")
		var start: Button = _difficulty_selector.get_node_or_null("Panel/StartButton")
		var back: Button = _difficulty_selector.get_node_or_null("Panel/BackButton")
		if left != null:
			left.pressed.connect(_on_difficulty_left_pressed)
		if right != null:
			right.pressed.connect(_on_difficulty_right_pressed)
		if start != null:
			start.pressed.connect(_on_difficulty_start_pressed)
		if back != null:
			back.pressed.connect(_on_difficulty_back_pressed)


func set_resume_available(available: bool) -> void:
	_continue_button.visible = available
	_continue_button.disabled = not available


func _has_save_data() -> bool:
	return _continue_button.visible


func _on_new_adventure_pressed() -> void:
	if _difficulty_selector != null:
		_current_difficulty_level = 0
		_update_difficulty_display()
		_difficulty_selector.visible = true
		%MenuContainer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		new_adventure_pressed.emit()


func _on_continue_pressed() -> void:
	continue_pressed.emit()


func _on_survivor_notes_pressed() -> void:
	survivor_notes_pressed.emit()


func _on_settings_pressed() -> void:
	settings_pressed.emit()


func _on_exit_game_pressed() -> void:
	exit_game_pressed.emit()


func _update_difficulty_display() -> void:
	var label: Label = _difficulty_selector.get_node_or_null("Panel/ButtonsContainer/DifficultyLabel")
	if label != null:
		label.text = _DIFFICULTY_DESCRIPTIONS.get(_current_difficulty_level, "")


func _on_difficulty_left_pressed() -> void:
	_current_difficulty_level = maxi(_current_difficulty_level - 1, 0)
	_update_difficulty_display()


func _on_difficulty_right_pressed() -> void:
	_current_difficulty_level = mini(_current_difficulty_level + 1, 3)
	_update_difficulty_display()


func _on_difficulty_start_pressed() -> void:
	if _difficulty_selector != null:
		_difficulty_selector.visible = false
		%MenuContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	difficulty_selected.emit(_current_difficulty_level)


func _on_difficulty_back_pressed() -> void:
	if _difficulty_selector != null:
		_difficulty_selector.visible = false
		%MenuContainer.mouse_filter = Control.MOUSE_FILTER_PASS
	difficulty_cancelled.emit()

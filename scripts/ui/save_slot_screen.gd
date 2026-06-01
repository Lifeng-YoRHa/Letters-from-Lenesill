class_name SaveSlotScreen
extends Control

signal slot_selected(slot_index: int)
signal slot_continue_requested(slot_index: int)
signal slot_delete_requested(slot_index: int)
signal back_pressed

enum Mode {
	LOAD,
	SAVE,
}

@export var mode: Mode = Mode.LOAD

@onready var _slot_0_button: Button = %Slot0Button
@onready var _slot_1_button: Button = %Slot1Button
@onready var _slot_2_button: Button = %Slot2Button
@onready var _title_label: Label = $TitleLabel
@onready var _confirm_panel: Control = $ConfirmPanel
@onready var _confirm_info_label: Label = $ConfirmPanel/CenterContainer/PanelContainer/VBoxContainer/InfoLabel
@onready var _continue_button: Button = $ConfirmPanel/CenterContainer/PanelContainer/VBoxContainer/ButtonRow/ContinueButton
@onready var _delete_button: Button = $ConfirmPanel/CenterContainer/PanelContainer/VBoxContainer/ButtonRow/DeleteButton
@onready var _cancel_button: Button = $ConfirmPanel/CenterContainer/PanelContainer/VBoxContainer/ButtonRow/CancelButton

var _slot_buttons: Array[Button] = []
var _save_load_manager: SaveLoadManager = null
var _current_selected_slot: int = -1


func _ready() -> void:
	_slot_buttons = [_slot_0_button, _slot_1_button, _slot_2_button]


func initialize(save_load_manager: SaveLoadManager, p_mode: Mode = Mode.LOAD) -> void:
	_save_load_manager = save_load_manager
	mode = p_mode
	_update_title()
	_refresh_buttons()


func _update_title() -> void:
	match mode:
		Mode.LOAD:
			_title_label.text = "Resume Adventure"
		Mode.SAVE:
			_title_label.text = "Save Adventure"


func _refresh_buttons() -> void:
	var statuses := _save_load_manager.get_all_slot_status()
	for i in range(_slot_buttons.size()):
		var info: Dictionary = statuses[i] if i < statuses.size() else {"has_save": false}
		_update_slot_button(i, info)


func _update_slot_button(index: int, info: Dictionary) -> void:
	var button := _slot_buttons[index]
	var has_save: bool = info.get("has_save", false)

	if has_save:
		var last_saved: int = info.get("last_saved_at", 0)
		var datetime := Time.get_datetime_string_from_unix_time(last_saved) if last_saved > 0 else "未知时间"
		var has_adventure: bool = info.get("has_adventure", false)
		var suffix := " (进行中)" if has_adventure else ""
		if mode == Mode.SAVE:
			suffix += " [覆盖]"
		button.text = "槽位 %d — %s%s" % [index + 1, datetime, suffix]
		button.disabled = false
	else:
		button.text = "槽位 %d — 空" % [index + 1]
		button.disabled = (mode == Mode.LOAD)


func _on_slot_0_pressed() -> void:
	_open_confirm_for_slot(0)


func _on_slot_1_pressed() -> void:
	_open_confirm_for_slot(1)


func _on_slot_2_pressed() -> void:
	_open_confirm_for_slot(2)


func _open_confirm_for_slot(slot_index: int) -> void:
	if mode == Mode.SAVE:
		slot_selected.emit(slot_index)
		return

	_current_selected_slot = slot_index
	var statuses := _save_load_manager.get_all_slot_status()
	var info: Dictionary = statuses[slot_index] if slot_index < statuses.size() else {"has_save": false}
	var has_save: bool = info.get("has_save", false)
	if not has_save:
		return

	var last_saved: int = info.get("last_saved_at", 0)
	var datetime := Time.get_datetime_string_from_unix_time(last_saved) if last_saved > 0 else "未知时间"
	_confirm_info_label.text = "槽位 %d — %s\n\n要做什么？" % [slot_index + 1, datetime]
	_confirm_panel.visible = true


func _hide_confirm_panel() -> void:
	_confirm_panel.visible = false
	_current_selected_slot = -1


func _on_continue_pressed() -> void:
	if _current_selected_slot >= 0:
		slot_continue_requested.emit(_current_selected_slot)
	_hide_confirm_panel()


func _on_delete_pressed() -> void:
	if _current_selected_slot >= 0:
		slot_delete_requested.emit(_current_selected_slot)
	_hide_confirm_panel()


func _on_cancel_pressed() -> void:
	_hide_confirm_panel()


func _on_back_pressed() -> void:
	back_pressed.emit()

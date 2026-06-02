class_name PasswordBoxScreen
extends Control

signal guess_submitted(password: int)
signal closed

@onready var _stamina_label: Label = %StaminaLabel
@onready var _hint_label: Label = %HintLabel
@onready var _reward_label: Label = %RewardLabel
@onready var _password_input: LineEdit = %PasswordInput


func show_screen(stamina_current: int, stamina_max: int) -> void:
	visible = true
	_stamina_label.text = "当前体力：%d / %d（每次猜测消耗1点）" % [stamina_current, stamina_max]
	_hint_label.text = ""
	_reward_label.visible = false
	_password_input.text = ""
	_password_input.grab_focus()


func show_hint(hint_text: String) -> void:
	_hint_label.text = hint_text


func update_stamina(stamina_current: int, stamina_max: int) -> void:
	_stamina_label.text = "当前体力：%d / %d（每次猜测消耗1点）" % [stamina_current, stamina_max]


func show_reward(reward_desc: String) -> void:
	_reward_label.text = reward_desc
	_reward_label.visible = true
	_hint_label.text = ""


func _on_confirm_pressed() -> void:
	var text := _password_input.text.strip_edges()
	if not text.is_valid_int():
		show_hint("请输入有效的数字。")
		return
	var password := int(text)
	if password < 10 or password > 99:
		show_hint("密码必须是两位数（10-99）。")
		return
	guess_submitted.emit(password)


func _on_close_pressed() -> void:
	closed.emit()


func _on_password_input_text_submitted(_new_text: String) -> void:
	_on_confirm_pressed()

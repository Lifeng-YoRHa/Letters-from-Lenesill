class_name EndingScreen
extends Control

signal return_to_main_menu_pressed

@onready var _title_label: Label = %TitleLabel
@onready var _stats_label: Label = %StatsLabel

func show_ending(ending_type: StringName, _stats: Dictionary) -> void:
	match ending_type:
		&"false":
			_title_label.text = "假结局"
		&"true":
			_title_label.text = "真结局"
		_:
			_title_label.text = "结局"
	visible = true
	# TODO: populate stats and narrative text


func _on_return_to_main_menu_pressed() -> void:
	return_to_main_menu_pressed.emit()

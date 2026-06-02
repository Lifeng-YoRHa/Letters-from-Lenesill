class_name EndingScreen
extends Control

signal return_to_main_menu_pressed

@onready var _title_label: Label = %TitleLabel
@onready var _stats_label: Label = %StatsLabel

func show_ending(ending_type: StringName, stats: Dictionary) -> void:
	match ending_type:
		&"false":
			_title_label.text = "假结局"
		&"true":
			_title_label.text = "真结局"
		&"death":
			_title_label.text = "游戏结束"
		&"victory":
			_title_label.text = "Victory"
		_:
			_title_label.text = "结局"

	var narrative: String = stats.get("narrative", "")
	if not narrative.is_empty():
		$NarrativeLabel.text = narrative

	visible = true


func _on_return_to_main_menu_pressed() -> void:
	return_to_main_menu_pressed.emit()

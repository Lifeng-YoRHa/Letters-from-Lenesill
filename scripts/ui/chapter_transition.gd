class_name ChapterTransition
extends Control

signal dismissed

@onready var _title_label: Label = %TitleLabel

func show_chapter(chapter: int) -> void:
	_title_label.text = "Chapter %d" % chapter
	visible = true
	# TODO: animate fade in, auto-dismiss after delay
	await get_tree().create_timer(2.0).timeout
	dismissed.emit()

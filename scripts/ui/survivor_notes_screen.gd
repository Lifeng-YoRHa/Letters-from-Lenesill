class_name SurvivorNotesScreen
extends Control

signal back_pressed
signal optional_carry_toggled(enabled: bool)

const _ENTRY_NAMES: Dictionary = {
	&"partner": "合作伙伴",
	&"spokesperson": "代言人",
	&"apprentice": "学徒",
	&"master": "师傅",
	&"wayfarer": "行路人",
	&"pathfinder": "探路者",
	&"hardship_survivor": "苦难幸存者",
	&"sufferer": "受难者",
	&"hoarder": "囤积者",
	&"miser": "吝啬鬼",
	&"trade_master": "交易大师",
	&"warrior": "战士",
	&"combat_master": "战斗大师",
	&"sports_enthusiast": "运动爱好者",
	&"extreme_sports": "极限运动爱好者",
	&"scavenger": "拾荒者",
	&"mischief_maker": "捣蛋鬼",
	&"chef": "厨师",
	&"scholar": "学者",
	&"hypnotist": "催眠师",
	&"electrician": "电工",
	&"adventurer": "冒险家",
	&"survivor": "幸存者",
	&"seeker": "求索者",
	&"martyr": "殉道人",
	&"backpacker": "背包客",
	&"escape_master": "逃脱大师",
	&"survival_expert": "生存专家",
	&"messenger": "信使",
	&"improviser": "即兴表演者",
	&"advanced_collector": "进阶收藏",
	&"witness": "见证者",
	&"berserker": "狂战士",
	&"magician": "魔术师",
	&"lightning_reflex": "闪电反应",
}

const _REWARD_TYPE_LABELS: Dictionary = {
	"relic": "解锁信物",
	"stat": "数值加成",
	"pocket": "口袋扩容",
	"safe_house": "安全屋升级",
	"backpack": "背包升级",
}

@onready var _optional_carry_check: CheckButton = %OptionalCarryCheck
@onready var _stats_label: Label = %StatsLabel
@onready var _notes_list: VBoxContainer = %NotesList
@onready var _back_button: Button = %BackButton

var _survivor_notes: SurvivorNotes = null
var _note_rows: Dictionary = {}  # StringName -> Control


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_optional_carry_check.toggled.connect(_on_optional_carry_toggled)


func initialize(survivor_notes: SurvivorNotes) -> void:
	_survivor_notes = survivor_notes
	_optional_carry_check.button_pressed = survivor_notes.is_optional_carry_enabled()
	_refresh_all()


func _refresh_all() -> void:
	if _survivor_notes == null:
		return

	_update_stats()
	_build_or_refresh_notes()


func _update_stats() -> void:
	var written := _survivor_notes.get_written_entries_count()
	var total := _survivor_notes.get_total_entries_count()
	_stats_label.text = "已解锁: %d / %d" % [written, total]


func _build_or_refresh_notes() -> void:
	var entry_ids := _survivor_notes.get_entry_ids()

	# Remove rows for entries that no longer exist
	for existing_id in _note_rows.keys():
		if not entry_ids.has(existing_id):
			var row: Control = _note_rows[existing_id]
			row.queue_free()
			_note_rows.erase(existing_id)

	# Build / refresh rows
	for entry_id in entry_ids:
		var data: Dictionary = _survivor_notes.get_entry_display_data(entry_id)
		if data.is_empty():
			continue

		var row: Control
		if _note_rows.has(entry_id):
			row = _note_rows[entry_id]
		else:
			row = _create_note_row(entry_id)
			_notes_list.add_child(row)
			_note_rows[entry_id] = row

		_update_note_row(row, data)


func _create_note_row(entry_id: StringName) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 80)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	# Left: name + description
	var left_vbox := VBoxContainer.new()
	left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left_vbox)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 18)
	left_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.name = "DescLabel"
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_vbox.add_child(desc_label)

	# Center: progress bar
	var center_vbox := VBoxContainer.new()
	center_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(center_vbox)

	var progress_bar := ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(180, 20)
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	center_vbox.add_child(progress_bar)

	var progress_label := Label.new()
	progress_label.name = "ProgressLabel"
	progress_label.add_theme_font_size_override("font_size", 12)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	center_vbox.add_child(progress_label)

	# Right: reward + stage status
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(right_vbox)

	var stage_label := Label.new()
	stage_label.name = "StageLabel"
	stage_label.add_theme_font_size_override("font_size", 14)
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_vbox.add_child(stage_label)

	var reward_label := Label.new()
	reward_label.name = "RewardLabel"
	reward_label.add_theme_font_size_override("font_size", 12)
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_vbox.add_child(reward_label)

	return panel


func _update_note_row(row: Control, data: Dictionary) -> void:
	var entry_id: StringName = data.id
	var name_text: String = _ENTRY_NAMES.get(entry_id, entry_id)
	var description: String = data.description
	var stages: Array = data.stages
	var current_progress: int = data.current_progress
	var completed_stage: int = data.completed_stage
	var is_written: bool = data.is_written

	var margin := row.get_child(0) as MarginContainer
	var hbox := margin.get_child(0) as HBoxContainer
	var left_vbox := hbox.get_child(0) as VBoxContainer
	var center_vbox := hbox.get_child(1) as VBoxContainer
	var right_vbox := hbox.get_child(2) as VBoxContainer

	var name_label: Label = left_vbox.get_node("NameLabel")
	var desc_label: Label = left_vbox.get_node("DescLabel")
	var progress_bar: ProgressBar = center_vbox.get_node("ProgressBar")
	var progress_label: Label = center_vbox.get_node("ProgressLabel")
	var stage_label: Label = right_vbox.get_node("StageLabel")
	var reward_label: Label = right_vbox.get_node("RewardLabel")

	# Name with completion mark
	if is_written:
		name_label.text = "★ %s" % name_text
		name_label.modulate = Color(0.9, 0.8, 0.5)
	elif completed_stage >= 0:
		name_label.text = "☆ %s" % name_text
		name_label.modulate = Color(1, 1, 1)
	else:
		name_label.text = name_text
		name_label.modulate = Color(0.7, 0.7, 0.7)

	desc_label.text = description

	# Progress bar: target is next uncompleted stage threshold, or max if all done
	var next_threshold: int = 0
	if is_written:
		next_threshold = stages[-1].threshold if stages.size() > 0 else current_progress
	elif completed_stage + 1 < stages.size():
		next_threshold = stages[completed_stage + 1].threshold
	elif stages.size() > 0:
		next_threshold = stages[-1].threshold
	else:
		next_threshold = current_progress

	if next_threshold <= 0:
		next_threshold = 1

	progress_bar.max_value = float(next_threshold)
	progress_bar.value = float(min(current_progress, next_threshold))
	progress_label.text = "%d / %d" % [current_progress, next_threshold]

	# Stage status
	if is_written:
		stage_label.text = "已完成 (%d/%d)" % [stages.size(), stages.size()]
	elif completed_stage >= 0:
		stage_label.text = "阶段 %d / %d" % [completed_stage + 1, stages.size()]
	else:
		stage_label.text = "未解锁 (%d/%d)" % [0, stages.size()]

	# Next reward preview
	if is_written:
		reward_label.text = "全部奖励已获取"
	elif completed_stage + 1 < stages.size():
		var next_stage: Dictionary = stages[completed_stage + 1]
		reward_label.text = "下一奖励: %s" % _format_reward(next_stage)
	else:
		reward_label.text = ""


func _format_reward(stage: Dictionary) -> String:
	var reward_type: String = stage.get("reward_type", "")
	var reward_value = stage.get("reward_value", null)

	match reward_type:
		"relic":
			return "信物: %s" % str(reward_value)
		"stat":
			if reward_value is Dictionary:
				var stat: String = reward_value.get("stat", "")
				var amount: int = reward_value.get("amount", 0)
				return "%s +%d" % [stat, amount]
			return "数值加成"
		"pocket":
			return "口袋扩容"
		"safe_house":
			return "安全屋升级"
		"backpack":
			return "背包升级"
		_:
			return "未知奖励"


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_optional_carry_toggled(enabled: bool) -> void:
	optional_carry_toggled.emit(enabled)

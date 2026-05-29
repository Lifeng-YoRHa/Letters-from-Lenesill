class_name EndingManager
extends RefCounted

signal false_ending_triggered(stats: AdventureStats)
signal true_ending_triggered(stats: AdventureStats)
signal final_chapter_unlocked()
signal ending_choice_presented(choice_a: String, choice_b: String)
signal run_completed(ending_type: StringName, stats: AdventureStats)

enum EndingType {
	NONE,
	FALSE_ENDING,
	TRUE_ENDING,
}

class AdventureStats:
	var chapters_completed: int = 0
	var total_gold_earned: int = 0
	var nodes_visited: int = 0
	var combats_won: int = 0
	var difficulty_level: int = 0
	var survivors_letters_collected: int = 0
	var play_time_seconds: int = 0

var _quest_manager: QuestManager
var _survivor_notes: SurvivorNotes
var _current_ending: EndingType = EndingType.NONE


func initialize(quest_manager: QuestManager, survivor_notes: SurvivorNotes) -> void:
	_quest_manager = quest_manager
	_survivor_notes = survivor_notes


func check_chapter4_boss_outcome() -> EndingType:
	if _quest_manager == null:
		return EndingType.NONE

	if _quest_manager.has_all_letters():
		# Present choice: True Ending path or False Ending
		ending_choice_presented.emit("拆封阅读 (进入最终章)", "恪尽职守 (进入假结局)")
		return EndingType.NONE  # Wait for player choice
	else:
		# Auto false ending
		return trigger_false_ending()


func choose_true_ending_path() -> EndingType:
	final_chapter_unlocked.emit()
	return EndingType.NONE  # Adventure continues into Final Chapter


func choose_false_ending_path() -> EndingType:
	return trigger_false_ending()


func trigger_false_ending() -> EndingType:
	_current_ending = EndingType.FALSE_ENDING
	var stats := _collect_stats()
	false_ending_triggered.emit(stats)
	_commit_meta_progression(stats, false)
	run_completed.emit(&"false_ending", stats)
	return EndingType.FALSE_ENDING


func trigger_true_ending() -> EndingType:
	_current_ending = EndingType.TRUE_ENDING
	var stats := _collect_stats()
	true_ending_triggered.emit(stats)
	_commit_meta_progression(stats, true)
	run_completed.emit(&"true_ending", stats)
	return EndingType.TRUE_ENDING


func check_final_boss_defeated() -> bool:
	# Called when Origin (Final Boss) is defeated
	return _current_ending == EndingType.NONE


func _collect_stats() -> AdventureStats:
	var stats := AdventureStats.new()
	stats.survivors_letters_collected = _quest_manager.get_survivors_letter_count() if _quest_manager != null else 0
	# Other stats would be collected from respective systems
	return stats


func _commit_meta_progression(stats: AdventureStats, is_true_ending: bool) -> void:
	if _survivor_notes == null:
		return

	# Unlock next difficulty
	var current_difficulty := stats.difficulty_level
	var new_unlocked := mini(current_difficulty + 1, 40)
	# This would be stored in MetaStateResource

	# Record ending
	var ending_id := &"true_ending" if is_true_ending else &"false_ending"
	# Add to unlocked_endings in MetaStateResource

	# Update Survivor Notes counters
	# (e.g., Survivor entry for first completion)
	if _survivor_notes.get_entry_completed_stage(&"survivor") < 0:
		_survivor_notes.add_progress(&"survivor", 1)

	# Witness entry for true ending
	if is_true_ending and _survivor_notes.get_entry_completed_stage(&"witness") < 0:
		_survivor_notes.add_progress(&"witness", 1)


func get_current_ending() -> EndingType:
	return _current_ending


func reset() -> void:
	_current_ending = EndingType.NONE

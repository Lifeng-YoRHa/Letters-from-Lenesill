class_name SurvivorNotes
extends RefCounted

signal entry_written(entry_id: StringName, stage_index: int, reward: String)
signal relic_unlocked(relic_id: StringName)
signal stat_upgraded(stat_id: StringName, new_value: int)

class Entry:
	var id: StringName
	var description: String
	var stages: Array[Dictionary] = []  # {threshold: int, reward_type: String, reward_value: Variant}
	var current_progress: int = 0
	var completed_stage: int = -1  # Highest completed stage index
	var is_written: bool = false

	func _init(p_id: StringName, p_desc: String, p_stages: Array[Dictionary]) -> void:
		id = p_id
		description = p_desc
		stages = p_stages

var _entries: Dictionary = {}  # StringName -> Entry
var _unlocked_relics: Array[StringName] = []
var _optional_carry_enabled: bool = true

# Cached upgrade values
var _energy_drink_bonus: int = 0
var _whetstone_bonus: int = 0
var _max_stamina_bonus: int = 0
var _starting_gold_bonus: int = 0
var _unarmed_damage_bonus: int = 0
var _dodge_reduction_bonus: int = 0
var _flee_cost_reduction: int = 0
var _last_effort_recovery_bonus: int = 0
var _flashlight_reveal_bonus: int = 0
var _starting_consumable_choices_bonus: int = 0
var _activated_cards_bonus: int = 0


func initialize() -> void:
	_setup_entries()
	_recalculate_all_bonuses()


func _setup_entries() -> void:
	_entries.clear()

	# 1. Partner
	_entries[&"partner"] = Entry.new(&"partner", "累计通过能量饮料恢复220/450/750点体力", [
		{threshold = 220, reward_type = "stat", reward_value = {"stat": "energy_drink_bonus", "amount": 1}},
		{threshold = 450, reward_type = "stat", reward_value = {"stat": "energy_drink_bonus", "amount": 1}},
		{threshold = 750, reward_type = "stat", reward_value = {"stat": "energy_drink_bonus", "amount": 1}},
	])

	# 2. Spokesperson
	_entries[&"spokesperson"] = Entry.new(&"spokesperson", "累计饮用240瓶能量饮料", [
		{threshold = 240, reward_type = "relic", reward_value = &"bottle_cap"},
	])

	# 3. Apprentice
	_entries[&"apprentice"] = Entry.new(&"apprentice", "累计通过磨刀石恢复80/200点武器耐久", [
		{threshold = 80,  reward_type = "stat", reward_value = {"stat": "whetstone_bonus", "amount": 1}},
		{threshold = 200, reward_type = "stat", reward_value = {"stat": "whetstone_bonus", "amount": 1}},
	])

	# 4. Master
	_entries[&"master"] = Entry.new(&"master", "累计使用100块磨刀石", [
		{threshold = 100, reward_type = "relic", reward_value = &"instruction_manual"},
	])

	# 5. Wayfarer
	_entries[&"wayfarer"] = Entry.new(&"wayfarer", "累计经过150/350/650/1100个非普通道路节点", [
		{threshold = 150,  reward_type = "stat", reward_value = {"stat": "max_stamina_bonus", "amount": 1}},
		{threshold = 350,  reward_type = "stat", reward_value = {"stat": "max_stamina_bonus", "amount": 1}},
		{threshold = 650,  reward_type = "stat", reward_value = {"stat": "max_stamina_bonus", "amount": 1}},
		{threshold = 1100, reward_type = "stat", reward_value = {"stat": "max_stamina_bonus", "amount": 1}},
	])

	# 6. Pathfinder
	_entries[&"pathfinder"] = Entry.new(&"pathfinder", "单次游戏经过75个非普通道路节点", [
		{threshold = 75, reward_type = "relic", reward_value = &"mp4"},
	])

	# 7. Hardship Survivor
	_entries[&"hardship_survivor"] = Entry.new(&"hardship_survivor", "累计进入第二章10次", [
		{threshold = 10, reward_type = "relic", reward_value = &"adrenaline_needle"},
	])

	# 8. Sufferer
	_entries[&"sufferer"] = Entry.new(&"sufferer", "累计进入第三章10次", [
		{threshold = 10, reward_type = "relic", reward_value = &"cross"},
	])

	# 9. Hoarder
	_entries[&"hoarder"] = Entry.new(&"hoarder", "累计获得100/250/500/800枚金币", [
		{threshold = 100, reward_type = "stat", reward_value = {"stat": "starting_gold_bonus", "amount": 1}},
		{threshold = 250, reward_type = "stat", reward_value = {"stat": "starting_gold_bonus", "amount": 1}},
		{threshold = 500, reward_type = "stat", reward_value = {"stat": "starting_gold_bonus", "amount": 1}},
		{threshold = 800, reward_type = "stat", reward_value = {"stat": "starting_gold_bonus", "amount": 1}},
	])

	# 10. Miser
	_entries[&"miser"] = Entry.new(&"miser", "累计获得1000枚金币", [
		{threshold = 1000, reward_type = "relic", reward_value = &"coin_purse"},
	])

	# 11. Trade Master
	_entries[&"trade_master"] = Entry.new(&"trade_master", "累计在黑市中消耗400枚金币", [
		{threshold = 400, reward_type = "relic", reward_value = &"friendship_token"},
	])

	# 12. Warrior
	_entries[&"warrior"] = Entry.new(&"warrior", "累计造成350/650点伤害", [
		{threshold = 350, reward_type = "stat", reward_value = {"stat": "unarmed_damage_bonus", "amount": 1}},
		{threshold = 650, reward_type = "stat", reward_value = {"stat": "unarmed_damage_bonus", "amount": 1}},
	])

	# 13. Combat Master
	_entries[&"combat_master"] = Entry.new(&"combat_master", "累计完成100次普通战斗或艰难战斗", [
		{threshold = 100, reward_type = "relic", reward_value = &"combat_manual"},
	])

	# 14. Sports Enthusiast
	_entries[&"sports_enthusiast"] = Entry.new(&"sports_enthusiast", "累计打出70/150次闪避", [
		{threshold = 70,  reward_type = "stat", reward_value = {"stat": "dodge_reduction_bonus", "amount": 1}},
		{threshold = 150, reward_type = "stat", reward_value = {"stat": "dodge_reduction_bonus", "amount": 1}},
	])

	# 15. Extreme Sports Enthusiast
	_entries[&"extreme_sports"] = Entry.new(&"extreme_sports", "累计打出200次闪避", [
		{threshold = 200, reward_type = "relic", reward_value = &"smoke_grenade"},
	])

	# 16. Scavenger
	_entries[&"scavenger"] = Entry.new(&"scavenger", "累计搜索200次废墟", [
		{threshold = 200, reward_type = "relic", reward_value = &"torn_doll"},
	])

	# 17. Mischief Maker
	_entries[&"mischief_maker"] = Entry.new(&"mischief_maker", "累计进入150次突发事件", [
		{threshold = 150, reward_type = "relic", reward_value = &"badge"},
	])

	# 18. Chef
	_entries[&"chef"] = Entry.new(&"chef", "累计使用火把消灭30名敌人", [
		{threshold = 30, reward_type = "relic", reward_value = &"lighter"},
	])

	# 19. Scholar
	_entries[&"scholar"] = Entry.new(&"scholar", "累计进入安全屋10/22/35/50/70次", [
		{threshold = 10, reward_type = "safe_house", reward_value = {"type": "scattered_consumables", "amount": 1}},
		{threshold = 22, reward_type = "safe_house", reward_value = {"type": "fridge_count", "amount": 1}},
		{threshold = 35, reward_type = "safe_house", reward_value = {"type": "piggy_bank", "amount": 1}},
		{threshold = 50, reward_type = "safe_house", reward_value = {"type": "anvil_uses", "amount": 1}},
		{threshold = 70, reward_type = "safe_house", reward_value = {"type": "scattered_consumables", "amount": 1}},
	])

	# 20. Hypnotist
	_entries[&"hypnotist"] = Entry.new(&"hypnotist", "累计进入安全屋100次", [
		{threshold = 100, reward_type = "relic", reward_value = &"eye_mask"},
	])

	# 21. Electrician
	_entries[&"electrician"] = Entry.new(&"electrician", "累计使用手电筒25/60次", [
		{threshold = 25, reward_type = "stat", reward_value = {"stat": "flashlight_reveal_bonus", "amount": 1}},
		{threshold = 60, reward_type = "stat", reward_value = {"stat": "flashlight_reveal_bonus", "amount": 1}},
	])

	# 22. Adventurer
	_entries[&"adventurer"] = Entry.new(&"adventurer", "累计使用手电筒85次", [
		{threshold = 85, reward_type = "relic", reward_value = &"battery"},
	])

	# 23. Survivor
	_entries[&"survivor"] = Entry.new(&"survivor", "通关一次游戏", [
		{threshold = 1, reward_type = "relic", reward_value = &"heart_of_hope"},
	])

	# 24. Seeker
	_entries[&"seeker"] = Entry.new(&"seeker", "进入一次隐藏地图", [
		{threshold = 1, reward_type = "relic", reward_value = &"compass"},
	])

	# 25. Martyr
	_entries[&"martyr"] = Entry.new(&"martyr", "累计进入第四章10次", [
		{threshold = 10, reward_type = "relic", reward_value = &"brilliant_statue"},
	])

	# 26. Backpacker
	_entries[&"backpacker"] = Entry.new(&"backpacker", "累计发现2/5种背包", [
		{threshold = 2, reward_type = "backpack", reward_value = {"type": "satchel_secondary", "size": Vector2i(1, 3)}},
		{threshold = 5, reward_type = "backpack", reward_value = {"type": "satchel_primary", "size": Vector2i(4, 4)}},
	])

	# 27. Escape Master
	_entries[&"escape_master"] = Entry.new(&"escape_master", "逃离战斗75/175次", [
		{threshold = 75,  reward_type = "stat", reward_value = {"stat": "flee_cost_reduction", "amount": 1}},
		{threshold = 175, reward_type = "stat", reward_value = {"stat": "flee_cost_reduction", "amount": 1}},
	])

	# 28. Survival Expert
	_entries[&"survival_expert"] = Entry.new(&"survival_expert", "使用300/800次消耗品", [
		{threshold = 300, reward_type = "stat", reward_value = {"stat": "starting_consumable_choices_bonus", "amount": 1}},
		{threshold = 800, reward_type = "stat", reward_value = {"stat": "starting_consumable_choices_bonus", "amount": 1}},
	])

	# 29. Messenger
	_entries[&"messenger"] = Entry.new(&"messenger", "完成10次委托任务", [
		{threshold = 10, reward_type = "relic", reward_value = &"torn_photo"},
	])

	# 30. Improviser
	_entries[&"improviser"] = Entry.new(&"improviser", "打出150/350张行动牌", [
		{threshold = 150, reward_type = "stat", reward_value = {"stat": "activated_cards_bonus", "amount": 1}},
		{threshold = 350, reward_type = "stat", reward_value = {"stat": "activated_cards_bonus", "amount": 1}},
	])

	# 31. Advanced Collector
	_entries[&"advanced_collector"] = Entry.new(&"advanced_collector", "幸存者笔记中解锁20个条目", [
		{threshold = 20, reward_type = "relic", reward_value = &"second_hand_drone"},
	])

	# 32. Witness
	_entries[&"witness"] = Entry.new(&"witness", "完成一次真正的结局", [
		{threshold = 1, reward_type = "relic", reward_value = &"dim_lantern"},
	])

	# 33. Berserker
	_entries[&"berserker"] = Entry.new(&"berserker", "体力不高于5点的情况下获得20/50次战斗胜利", [
		{threshold = 20, reward_type = "stat", reward_value = {"stat": "last_effort_recovery_bonus", "amount": 1}},
		{threshold = 50, reward_type = "stat", reward_value = {"stat": "last_effort_recovery_bonus", "amount": 1}},
	])

	# 34. Magician
	_entries[&"magician"] = Entry.new(&"magician", "在战斗中从口袋中使用物品100次", [
		{threshold = 100, reward_type = "pocket", reward_value = {"size": Vector2i(1, 3)}},
	])

	# 35. Lightning Reflex
	_entries[&"lightning_reflex"] = Entry.new(&"lightning_reflex", "在进入战斗的第一回合即取得胜利，完成30次", [
		{threshold = 30, reward_type = "relic", reward_value = &"running_shoes"},
	])


# === Progress Tracking ===

func add_progress(entry_id: StringName, amount: int) -> void:
	var entry := _entries.get(entry_id) as Entry
	if entry == null:
		return
	if entry.is_written:
		return

	entry.current_progress += amount
	_check_stage_completion(entry)


func set_progress(entry_id: StringName, value: int) -> void:
	var entry := _entries.get(entry_id) as Entry
	if entry == null:
		return
	if entry.is_written:
		return

	entry.current_progress = value
	_check_stage_completion(entry)


func _check_stage_completion(entry: Entry) -> void:
	for i in range(entry.stages.size()):
		if i <= entry.completed_stage:
			continue
		var stage := entry.stages[i]
		if entry.current_progress >= stage.threshold:
			entry.completed_stage = i
			_grant_reward(entry, i, stage)
			entry_written.emit(entry.id, i, _format_reward(stage))

	# Mark as fully written if all stages completed
	if entry.completed_stage >= entry.stages.size() - 1:
		entry.is_written = true


func _grant_reward(entry: Entry, stage_index: int, stage: Dictionary) -> void:
	match stage.reward_type:
		"relic":
			var relic_id: StringName = stage.reward_value
			if not _unlocked_relics.has(relic_id):
				_unlocked_relics.append(relic_id)
				relic_unlocked.emit(relic_id)
		"stat":
			var stat_info: Dictionary = stage.reward_value
			_apply_stat_upgrade(stat_info.stat, stat_info.amount)
		"pocket":
			pass  # Handled by BackpackManager
		"safe_house", "backpack":
			pass  # Handled by respective systems


func _apply_stat_upgrade(stat_name: StringName, amount: int) -> void:
	match stat_name:
		&"energy_drink_bonus": _energy_drink_bonus += amount
		&"whetstone_bonus": _whetstone_bonus += amount
		&"max_stamina_bonus": _max_stamina_bonus += amount
		&"starting_gold_bonus": _starting_gold_bonus += amount
		&"unarmed_damage_bonus": _unarmed_damage_bonus += amount
		&"dodge_reduction_bonus": _dodge_reduction_bonus += amount
		&"flee_cost_reduction": _flee_cost_reduction += amount
		&"last_effort_recovery_bonus": _last_effort_recovery_bonus += amount
		&"flashlight_reveal_bonus": _flashlight_reveal_bonus += amount
		&"starting_consumable_choices_bonus": _starting_consumable_choices_bonus += amount
		&"activated_cards_bonus": _activated_cards_bonus += amount
	stat_upgraded.emit(stat_name, amount)


func _recalculate_all_bonuses() -> void:
	_energy_drink_bonus = 0
	_whetstone_bonus = 0
	_max_stamina_bonus = 0
	_starting_gold_bonus = 0
	_unarmed_damage_bonus = 0
	_dodge_reduction_bonus = 0
	_flee_cost_reduction = 0
	_last_effort_recovery_bonus = 0
	_flashlight_reveal_bonus = 0
	_starting_consumable_choices_bonus = 0
	_activated_cards_bonus = 0

	for entry in _entries.values():
		for i in range(entry.completed_stage + 1):
			if i < entry.stages.size():
				var stage: Dictionary = entry.stages[i]
				if stage.reward_type == "stat":
					_apply_stat_upgrade(stage.reward_value.stat, stage.reward_value.amount)


# === Queries ===

func get_entry_progress(entry_id: StringName) -> int:
	var entry := _entries.get(entry_id) as Entry
	if entry == null:
		return 0
	return entry.current_progress


func get_entry_completed_stage(entry_id: StringName) -> int:
	var entry := _entries.get(entry_id) as Entry
	if entry == null:
		return -1
	return entry.completed_stage


func is_entry_written(entry_id: StringName) -> bool:
	var entry := _entries.get(entry_id) as Entry
	if entry == null:
		return false
	return entry.is_written


func get_unlocked_relics() -> Array[StringName]:
	return _unlocked_relics.duplicate()


func is_relic_unlocked(relic_id: StringName) -> bool:
	return _unlocked_relics.has(relic_id)


func get_written_entries_count() -> int:
	var count := 0
	for entry in _entries.values():
		if entry.is_written:
			count += 1
	return count


func get_total_entries_count() -> int:
	return _entries.size()


# === Upgrade Value Getters ===

func get_energy_drink_bonus() -> int: return _energy_drink_bonus if _optional_carry_enabled else 0
func get_whetstone_bonus() -> int: return _whetstone_bonus if _optional_carry_enabled else 0
func get_max_stamina_bonus() -> int: return _max_stamina_bonus if _optional_carry_enabled else 0
func get_starting_gold_bonus() -> int: return _starting_gold_bonus if _optional_carry_enabled else 0
func get_unarmed_damage_bonus() -> int: return _unarmed_damage_bonus if _optional_carry_enabled else 0
func get_dodge_reduction_bonus() -> int: return _dodge_reduction_bonus if _optional_carry_enabled else 0
func get_flee_cost_reduction() -> int: return _flee_cost_reduction if _optional_carry_enabled else 0
func get_last_effort_recovery_bonus() -> int: return _last_effort_recovery_bonus if _optional_carry_enabled else 0
func get_flashlight_reveal_bonus() -> int: return _flashlight_reveal_bonus if _optional_carry_enabled else 0
func get_starting_consumable_choices_bonus() -> int: return _starting_consumable_choices_bonus if _optional_carry_enabled else 0
func get_activated_cards_bonus() -> int: return _activated_cards_bonus if _optional_carry_enabled else 0


# === Optional Carry ===

func set_optional_carry(enabled: bool) -> void:
	_optional_carry_enabled = enabled


func is_optional_carry_enabled() -> bool:
	return _optional_carry_enabled


# === Serialization Helpers ===

func get_all_progress() -> Dictionary:
	var result := {}
	for entry_id in _entries.keys():
		var entry := _entries[entry_id] as Entry
		result[entry_id] = {
			"progress": entry.current_progress,
			"completed_stage": entry.completed_stage,
			"is_written": entry.is_written,
		}
	return result


func load_all_progress(data: Dictionary) -> void:
	for entry_id in data.keys():
		var entry := _entries.get(entry_id) as Entry
		if entry == null:
			continue
		var entry_data: Dictionary = data[entry_id]
		entry.current_progress = entry_data.get("progress", 0)
		entry.completed_stage = entry_data.get("completed_stage", -1)
		entry.is_written = entry_data.get("is_written", false)
	_recalculate_all_bonuses()


func _format_reward(stage: Dictionary) -> String:
	match stage.reward_type:
		"relic": return "解锁信物: %s" % stage.reward_value
		"stat": return "%s +%d" % [stage.reward_value.stat, stage.reward_value.amount]
		"pocket": return "口袋扩容"
		_: return "未知奖励"

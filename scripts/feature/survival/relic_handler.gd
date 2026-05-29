class_name RelicHandler
extends RefCounted

signal relic_triggered(relic_id: StringName, effect_description: String)
signal relic_destroyed(relic_id: StringName)

var _held_relics: Array[RelicData] = []
var _used_once_relics: Array[StringName] = []  # Tracks used once-per-adventure relics
var _adrenaline_needle_available: bool = true


func initialize() -> void:
	_held_relics.clear()
	_used_once_relics.clear()
	_adrenaline_needle_available = true


func add_relic(relic: RelicData) -> bool:
	if has_relic(relic.id):
		return false
	_held_relics.append(relic)
	return true


func remove_relic(relic_id: StringName) -> bool:
	for i in range(_held_relics.size()):
		if _held_relics[i].id == relic_id:
			_held_relics.remove_at(i)
			return true
	return false


func has_relic(relic_id: StringName) -> bool:
	for relic in _held_relics:
		if relic.id == relic_id:
			return true
	return false


func get_held_relics() -> Array[RelicData]:
	return _held_relics.duplicate()


# === Passive Bonus Queries ===

func get_damage_bonus() -> int:
	var bonus := 0
	if has_relic(&"cross"):
		bonus += 1
	if has_relic(&"combat_manual"):
		bonus += 2
	if has_relic(&"brilliant_statue"):
		bonus += 2
	return bonus


func get_max_stamina_bonus() -> int:
	var bonus := 0
	if has_relic(&"cross"):
		bonus += 2
	if has_relic(&"brilliant_statue"):
		bonus += 3
	return bonus


func get_damage_reduction() -> int:
	if has_relic(&"smoke_grenade"):
		return 2
	return 0


func get_dodge_reduction_bonus() -> int:
	return 0  # Base dodge reduction is handled by Survivor Notes


func get_movement_cost_reduction() -> int:
	if has_relic(&"mp4"):
		return 1
	return 0


func get_flee_cost_reduction() -> int:
	return 0  # Handled by Survivor Notes Escape Master


func get_energy_drink_bonus() -> int:
	if has_relic(&"bottle_cap"):
		return 2
	return 0


func get_flashlight_reveal_bonus() -> int:
	if has_relic(&"battery"):
		return 1
	return 0


func get_torch_damage() -> int:
	return 30  # Base torch damage; relics don't modify this directly


func get_quest_gold_bonus() -> int:
	if has_relic(&"torn_photo"):
		return 5
	return 0


func get_shop_sell_discount_percent() -> float:
	if has_relic(&"friendship_token"):
		return 0.30
	return 0.0


func is_theft_blocked() -> bool:
	return has_relic(&"badge")


func is_robbery_blocked() -> bool:
	return has_relic(&"badge")


func is_hard_combat_debuff_blocked() -> bool:
	return has_relic(&"eye_mask")


func is_boss_debuff_blocked() -> bool:
	return has_relic(&"dim_lantern")


func is_ruins_search_cost_reduced() -> bool:
	return has_relic(&"torn_doll")


func is_whetstone_atk_penalty_waived() -> bool:
	return has_relic(&"instruction_manual")


func get_actions_per_turn_bonus() -> int:
	if has_relic(&"running_shoes"):
		return 1
	return 0


# === Triggered Effects ===

func on_combat_start(enemy_data: EnemyData) -> int:
	var bonus_damage := 0
	if has_relic(&"lighter"):
		bonus_damage = 5
		relic_triggered.emit(&"lighter", "Dealt 5 damage at combat start.")
	return bonus_damage


func on_death_save(current_stamina: int) -> int:
	if not _adrenaline_needle_available:
		return current_stamina
	if has_relic(&"adrenaline_needle"):
		_adrenaline_needle_available = false
		relic_triggered.emit(&"adrenaline_needle", "Stamina restored to 10. Relic destroyed.")
		relic_destroyed.emit(&"adrenaline_needle")
		remove_relic(&"adrenaline_needle")
		return 10
	return current_stamina


func on_chapter_start() -> Array[RelicData]:
	var granted: Array[RelicData] = []
	if has_relic(&"heart_of_hope"):
		# Game flow layer should handle random relic selection
		relic_triggered.emit(&"heart_of_hope", "Granting random relic at chapter start.")
		granted.append(null)  # Placeholder; actual random selection happens in game flow
	return granted


func use_coin_purse() -> int:
	if has_relic(&"coin_purse") and not _used_once_relics.has(&"coin_purse"):
		_used_once_relics.append(&"coin_purse")
		relic_triggered.emit(&"coin_purse", "Gained 16 gold. Relic destroyed.")
		relic_destroyed.emit(&"coin_purse")
		remove_relic(&"coin_purse")
		return 16
	return 0


func use_second_hand_drone() -> bool:
	return has_relic(&"second_hand_drone")


func get_compass_quest_target_distance() -> bool:
	return has_relic(&"compass")

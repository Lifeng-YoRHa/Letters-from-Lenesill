class_name CombatState
extends RefCounted

signal phase_changed(new_phase: GameEnums.CombatPhase, old_phase: GameEnums.CombatPhase)
signal round_started(round_number: int)
signal enemy_hp_changed(new_hp: int, old_hp: int)
signal activated_cards_changed(cards: Array[ActionCardData])
signal actions_used_changed(used: int, max_actions: int)
signal debuff_applied(debuff: GameEnums.DebuffType)
signal debuff_removed(debuff: GameEnums.DebuffType)
signal courage_toggled(active: bool)
signal dodge_toggled(active: bool, reduction: int)
signal analyze_toggled(active: bool)
signal last_effort_toggled(used: bool)
signal extra_action_toggled(active: bool)
signal boss_emergency_heal_toggled(used: bool)

var enemy_data: EnemyData:
	get:
		return _enemy_data

var encounter_type: GameEnums.EnemyType:
	get:
		return _encounter_type

var combat_phase: GameEnums.CombatPhase:
	get:
		return _combat_phase

var round_number: int:
	get:
		return _round_number

var enemy_current_hp: int:
	get:
		return _enemy_current_hp

var activated_cards: Array[ActionCardData]:
	get:
		return _activated_cards.duplicate()

var actions_used_this_turn: int:
	get:
		return _actions_used_this_turn

var max_actions_this_turn: int:
	get:
		return _max_actions_this_turn

var active_debuffs: Array[GameEnums.DebuffType]:
	get:
		return _active_debuffs.duplicate()

var courage_active: bool:
	get:
		return _courage_active

var dodge_active: bool:
	get:
		return _dodge_active

var dodge_reduction: int:
	get:
		return _dodge_reduction

var analyze_active: bool:
	get:
		return _analyze_active

var last_effort_used: bool:
	get:
		return _last_effort_used

var extra_action_next_turn: bool:
	get:
		return _extra_action_next_turn

var boss_emergency_heal_used: bool:
	get:
		return _boss_emergency_heal_used

var _enemy_data: EnemyData
var _encounter_type: GameEnums.EnemyType
var _combat_phase: GameEnums.CombatPhase
var _round_number: int = 0
var _enemy_current_hp: int = 0
var _activated_cards: Array[ActionCardData] = []
var _actions_used_this_turn: int = 0
var _max_actions_this_turn: int = 3
var _active_debuffs: Array[GameEnums.DebuffType] = []
var _courage_active: bool = false
var _dodge_active: bool = false
var _dodge_reduction: int = 4
var _analyze_active: bool = false
var _last_effort_used: bool = false
var _extra_action_next_turn: bool = false
var _boss_emergency_heal_used: bool = false


func initialize(enemy: EnemyData, encounter: GameEnums.EnemyType) -> void:
	_enemy_data = enemy
	_encounter_type = encounter
	_enemy_current_hp = enemy.base_hp
	_combat_phase = GameEnums.CombatPhase.SETUP
	_round_number = 0
	_actions_used_this_turn = 0
	_max_actions_this_turn = 3
	_courage_active = false
	_dodge_active = false
	_dodge_reduction = 4
	_analyze_active = false
	_last_effort_used = false
	_extra_action_next_turn = false
	_boss_emergency_heal_used = false
	_activated_cards.clear()
	_active_debuffs.clear()


func set_phase(phase: GameEnums.CombatPhase) -> void:
	var old: GameEnums.CombatPhase = _combat_phase
	_combat_phase = phase
	phase_changed.emit(phase, old)


func start_round(number: int) -> void:
	_round_number = number
	_actions_used_this_turn = 0
	round_started.emit(number)


func set_enemy_hp(hp: int) -> void:
	var old: int = _enemy_current_hp
	_enemy_current_hp = hp
	enemy_hp_changed.emit(hp, old)


func damage_enemy(amount: int) -> int:
	set_enemy_hp(_enemy_current_hp - amount)
	return _enemy_current_hp


func set_activated_cards(cards: Array[ActionCardData]) -> void:
	_activated_cards = cards.duplicate()
	activated_cards_changed.emit(_activated_cards.duplicate())


func set_actions_used(used: int) -> void:
	_actions_used_this_turn = used
	actions_used_changed.emit(used, _max_actions_this_turn)


func set_max_actions(max_actions: int) -> void:
	_max_actions_this_turn = max_actions
	actions_used_changed.emit(_actions_used_this_turn, max_actions)


func add_debuff(debuff: GameEnums.DebuffType) -> void:
	if not _active_debuffs.has(debuff):
		_active_debuffs.append(debuff)
		debuff_applied.emit(debuff)


func remove_debuff(debuff: GameEnums.DebuffType) -> void:
	_active_debuffs.erase(debuff)
	debuff_removed.emit(debuff)


func set_courage_active(active: bool) -> void:
	_courage_active = active
	courage_toggled.emit(active)


func set_dodge_active(active: bool, reduction: int = 4) -> void:
	_dodge_active = active
	_dodge_reduction = reduction
	dodge_toggled.emit(active, reduction)


func set_analyze_active(active: bool) -> void:
	_analyze_active = active
	analyze_toggled.emit(active)


func set_last_effort_used(used: bool) -> void:
	_last_effort_used = used
	last_effort_toggled.emit(used)


func set_extra_action_next_turn(active: bool) -> void:
	_extra_action_next_turn = active
	extra_action_toggled.emit(active)


func set_boss_emergency_heal_used(used: bool) -> void:
	_boss_emergency_heal_used = used
	boss_emergency_heal_toggled.emit(used)


func get_remaining_actions() -> int:
	return _max_actions_this_turn - _actions_used_this_turn

class_name CombatManager
extends RefCounted

signal combat_started()
signal combat_ended(result: GameEnums.CombatPhase)
signal player_turn_started(activated_cards: Array[ActionCardData])
signal enemy_turn_started()
signal enemy_action_resolved(action: EnemyAction)
signal player_took_damage(amount: int, remaining_stamina: int)
signal enemy_took_damage(amount: int, remaining_hp: int)
signal action_consumed(used: int, max_actions: int)
signal round_started(round_number: int)
signal card_played(card: ActionCardData)

var combat_state: CombatState:
	get:
		return _combat_state

var player_stamina: Stamina:
	get:
		return _player_stamina

var backpack_manager: BackpackManager = null

var _combat_state: CombatState
var _player_stamina: Stamina
var _enemy_ai: EnemyAI
var _damage_calculator: DamageCalculator
var _full_deck: Array[ActionCardData]
var _activated_card_count: int
var _rng: RandomNumberGenerator
var _is_active: bool = false


func initialize(
	enemy: EnemyData,
	encounter_type: GameEnums.EnemyType,
	stamina: Stamina,
	full_deck: Array[ActionCardData],
	p_backpack_manager: BackpackManager = null,
	enemy_ai: EnemyAI = null,
	damage_calculator: DamageCalculator = null,
	activated_card_count: int = 3,
	rng: RandomNumberGenerator = null
) -> void:
	_combat_state = CombatState.new()
	_combat_state.initialize(enemy, encounter_type)
	_player_stamina = stamina
	backpack_manager = p_backpack_manager
	_enemy_ai = enemy_ai if enemy_ai != null else EnemyAI.new()
	_damage_calculator = damage_calculator if damage_calculator != null else DamageCalculator.new()
	_full_deck = full_deck.duplicate()
	_activated_card_count = activated_card_count
	_rng = rng if rng != null else RandomNumberGenerator.new()
	_is_active = false


func start_combat() -> void:
	if _is_active:
		return
	_is_active = true
	combat_started.emit()
	_start_round(1)


func start_player_turn() -> Array[ActionCardData]:
	if not _is_active:
		return []
	if _combat_state.combat_phase == GameEnums.CombatPhase.VICTORY \
		or _combat_state.combat_phase == GameEnums.CombatPhase.DEFEAT \
		or _combat_state.combat_phase == GameEnums.CombatPhase.FLED:
		return []

	_combat_state.set_phase(GameEnums.CombatPhase.PLAYER_TURN)
	_combat_state.set_actions_used(0)

	var activated := _select_activated_cards()
	_combat_state.set_activated_cards(activated)
	player_turn_started.emit(activated.duplicate())

	return activated.duplicate()


func consume_action() -> bool:
	if not _is_active:
		return false
	if _combat_state.combat_phase != GameEnums.CombatPhase.PLAYER_TURN:
		return false
	if _combat_state.get_remaining_actions() <= 0:
		return false

	var new_used := _combat_state.actions_used_this_turn + 1
	_combat_state.set_actions_used(new_used)
	action_consumed.emit(new_used, _combat_state.max_actions_this_turn)
	return true


func end_player_turn() -> void:
	if not _is_active:
		return
	if _combat_state.combat_phase != GameEnums.CombatPhase.PLAYER_TURN:
		return
	_start_enemy_turn()


func deal_damage_to_enemy(amount: int) -> void:
	if not _is_active:
		return
	if amount <= 0:
		return

	_combat_state.damage_enemy(amount)
	var new_hp := _combat_state.enemy_current_hp
	enemy_took_damage.emit(amount, new_hp)

	if new_hp <= 0:
		_end_combat(GameEnums.CombatPhase.VICTORY)


func apply_damage_to_player(amount: int) -> void:
	if not _is_active:
		return
	if amount <= 0:
		return

	_player_stamina.deduct(amount)
	var remaining := _player_stamina.current_stamina
	player_took_damage.emit(amount, remaining)

	if remaining <= 0:
		_end_combat(GameEnums.CombatPhase.DEFEAT)


func check_defeat_if_no_victory() -> void:
	if not _is_active:
		return
	if _player_stamina.current_stamina <= 0:
		_end_combat(GameEnums.CombatPhase.DEFEAT)


func heal_enemy(amount: int) -> void:
	if not _is_active:
		return
	if amount <= 0:
		return

	var max_hp := _combat_state.enemy_data.base_hp
	var new_hp := mini(_combat_state.enemy_current_hp + amount, max_hp)
	_combat_state.set_enemy_hp(new_hp)


func resolve_enemy_turn() -> void:
	if not _is_active:
		return
	if _combat_state.combat_phase != GameEnums.CombatPhase.ENEMY_TURN:
		return

	var action := _enemy_ai.decide_turn_action(_combat_state.enemy_data, _combat_state)
	enemy_action_resolved.emit(action)

	if action.is_emergency_heal:
		heal_enemy(action.self_heal)
	else:
		for i in range(action.attack_count):
			var raw_dmg := action.damage_to_player
			var final_dmg := _damage_calculator.calculate_enemy_damage(raw_dmg, _combat_state)
			apply_damage_to_player(final_dmg)
			if _combat_state.dodge_active:
				_combat_state.set_dodge_active(false)
			if not _is_active:
				return

	_start_next_round()


func flee() -> void:
	if not _is_active:
		return
	_end_combat(GameEnums.CombatPhase.FLED)


func is_combat_active() -> bool:
	return _is_active


func get_remaining_actions() -> int:
	if not _is_active:
		return 0
	return _combat_state.get_remaining_actions()


func record_card_played(card: ActionCardData) -> void:
	card_played.emit(card)


func _start_round(number: int) -> void:
	_combat_state.start_round(number)
	round_started.emit(number)
	start_player_turn()


func _start_enemy_turn() -> void:
	_combat_state.set_phase(GameEnums.CombatPhase.ENEMY_TURN)
	enemy_turn_started.emit()


func _start_next_round() -> void:
	if not _is_active:
		return
	var next_round := _combat_state.round_number + 1
	_start_round(next_round)


func _select_activated_cards() -> Array[ActionCardData]:
	if _full_deck.is_empty():
		return []

	var deck: Array = _full_deck.duplicate()
	for i in range(deck.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var temp = deck[i]
		deck[i] = deck[j]
		deck[j] = temp

	var count := mini(_activated_card_count, deck.size())
	var result: Array[ActionCardData] = []
	for i in range(count):
		result.append(deck[i])

	return result


func _end_combat(result: GameEnums.CombatPhase) -> void:
	if not _is_active:
		return
	_is_active = false
	_combat_state.set_phase(result)
	combat_ended.emit(result)

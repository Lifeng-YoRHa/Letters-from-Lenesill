class_name EnemyAI
extends RefCounted

func decide_turn_action(enemy_data: EnemyData, combat_state: CombatState) -> EnemyAction:
	var action := EnemyAction.new()

	if _should_use_emergency_heal(enemy_data, combat_state):
		action.is_emergency_heal = true
		action.self_heal = int(enemy_data.base_hp * 0.3)
		return action

	action.damage_to_player = _get_attack_power(enemy_data, combat_state)
	action.attack_count = _get_attack_count(enemy_data, combat_state)
	action.self_heal = _get_self_heal(enemy_data, combat_state)
	action.skip_next_player_turn = _should_skip_player_turn(enemy_data, combat_state)

	return action


func _get_attack_power(enemy_data: EnemyData, combat_state: CombatState) -> int:
	return enemy_data.base_attack


func _get_attack_count(enemy_data: EnemyData, combat_state: CombatState) -> int:
	return 1


func _get_self_heal(enemy_data: EnemyData, combat_state: CombatState) -> int:
	return 0


func _should_use_emergency_heal(enemy_data: EnemyData, combat_state: CombatState) -> bool:
	if combat_state.encounter_type != GameEnums.EnemyType.BOSS:
		return false
	if combat_state.boss_emergency_heal_used:
		return false
	return combat_state.enemy_current_hp <= enemy_data.base_hp * 0.5


func _should_skip_player_turn(enemy_data: EnemyData, combat_state: CombatState) -> bool:
	return false

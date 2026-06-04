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
	action.self_damage = _get_self_damage(enemy_data, combat_state)
	action.skip_next_player_turn = _should_skip_player_turn(enemy_data, combat_state)

	return action


func _get_attack_power(enemy_data: EnemyData, combat_state: CombatState) -> int:
	var power := enemy_data.base_attack
	var params := enemy_data.mechanic_params
	var hp := combat_state.enemy_current_hp

	# hp_threshold_attack_up
	var threshold: int = params.get("threshold", 0)
	var bonus: int = params.get("attack_bonus", 0)
	if threshold > 0 and bonus > 0 and hp <= threshold:
		power += bonus

	# self_damage_attack_up (bonus is unconditional on top of base)
	var self_damage_bonus: int = params.get("attack_bonus", 0)
	if params.has("self_damage") and self_damage_bonus > 0:
		power += self_damage_bonus

	# hp_tiered_attack_up
	if params.has("tier1_hp"):
		if hp <= params.get("tier3_hp", 0) and params.get("tier3_bonus", 0) > 0:
			power += params.get("tier3_bonus", 0)
		elif hp <= params.get("tier2_hp", 0) and params.get("tier2_bonus", 0) > 0:
			power += params.get("tier2_bonus", 0)
		elif hp <= params.get("tier1_hp", 0) and params.get("tier1_bonus", 0) > 0:
			power += params.get("tier1_bonus", 0)

	return power


func _get_attack_count(enemy_data: EnemyData, combat_state: CombatState) -> int:
	var mechanic := enemy_data.special_mechanic_id
	var round_num := combat_state.round_number

	match mechanic:
		&"double_attack_turn2":
			if round_num == 2:
				return 2
		&"double_attack_turn3":
			if round_num == 3:
				return 2
		&"double_attack_turn4":
			if round_num == 4:
				return 2

	return 1


func _get_self_heal(enemy_data: EnemyData, combat_state: CombatState) -> int:
	var params := enemy_data.mechanic_params

	# heal_per_turn
	if params.has("heal"):
		return params.get("heal", 0)

	# hp_threshold_heal_once (one-time emergency heal for hard enemies)
	var threshold: int = params.get("threshold", 0)
	var heal: int = params.get("heal_amount", 0)
	if threshold > 0 and heal > 0 and combat_state.enemy_current_hp <= threshold and not combat_state.boss_emergency_heal_used:
		return heal

	return 0


func _get_self_damage(enemy_data: EnemyData, combat_state: CombatState) -> int:
	var params := enemy_data.mechanic_params
	if params.has("self_damage"):
		return params.get("self_damage", 0)
	return 0


func _should_use_emergency_heal(enemy_data: EnemyData, combat_state: CombatState) -> bool:
	if combat_state.boss_emergency_heal_used:
		return false

	var mechanic := enemy_data.special_mechanic_id
	var params := enemy_data.mechanic_params
	var hp := combat_state.enemy_current_hp

	# Boss universal emergency heal: once at <= 50% max HP
	if combat_state.encounter_type == GameEnums.EnemyType.BOSS:
		return hp <= enemy_data.base_hp * 0.5

	# Hard combat "hp_threshold_heal_once" uses the same flag for one-time heals
	var threshold: int = params.get("threshold", 0)
	var heal: int = params.get("heal_amount", 0)
	if mechanic == &"hp_threshold_heal_once" and threshold > 0 and heal > 0 and hp <= threshold:
		return true

	return false


func _should_skip_player_turn(enemy_data: EnemyData, combat_state: CombatState) -> bool:
	var params := enemy_data.mechanic_params
	var hp := combat_state.enemy_current_hp

	if params.has("tier1_hp") and params.has("tier2_hp"):
		var tier2: int = params.get("tier2_hp", 0)
		if tier2 > 0 and hp <= tier2:
			return true
		var tier1: int = params.get("tier1_hp", 0)
		if tier1 > 0 and hp <= tier1:
			return true

	return false


func get_enemy_damage_reduction(enemy_data: EnemyData, combat_state: CombatState) -> int:
	var params := enemy_data.mechanic_params
	var hp := combat_state.enemy_current_hp

	var threshold: int = params.get("threshold", 0)
	var reduction: int = params.get("damage_reduction", 2)
	if threshold > 0 and hp <= threshold:
		return reduction

	return 0

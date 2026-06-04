extends GdUnitTestSuite


func _make_enemy(hp: int, atk: int, mechanic: StringName = &"", params: Dictionary = {}) -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"test_enemy"
	enemy.base_hp = hp
	enemy.base_attack = atk
	enemy.special_mechanic_id = mechanic
	enemy.mechanic_params = params
	return enemy


func _make_combat_state(enemy: EnemyData, encounter_type: GameEnums.EnemyType, round_num: int = 1) -> CombatState:
	var state := CombatState.new()
	state.initialize(enemy, encounter_type)
	state.start_round(round_num)
	return state


func test_double_attack_turn2_attacks_twice_on_turn2():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 3, &"double_attack_turn2")
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 2)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.attack_count).is_equal(2)
	assert_int(action.damage_to_player).is_equal(3)


func test_double_attack_turn2_attacks_once_on_turn1():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 3, &"double_attack_turn2")
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 1)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.attack_count).is_equal(1)


func test_double_attack_turn3_attacks_twice_on_turn3():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 3, &"double_attack_turn3")
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 3)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.attack_count).is_equal(2)


func test_double_attack_turn4_attacks_twice_on_turn4():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 3, &"double_attack_turn4")
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 4)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.attack_count).is_equal(2)


func test_hp_threshold_attack_up_boosts_when_low_hp():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 3, &"hp_threshold_attack_up", {"threshold": 11, "attack_bonus": 1})
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 1)
	state.set_enemy_hp(11)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.damage_to_player).is_equal(4)


func test_hp_threshold_attack_up_no_boost_when_high_hp():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 3, &"hp_threshold_attack_up", {"threshold": 11, "attack_bonus": 1})
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 1)
	state.set_enemy_hp(12)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.damage_to_player).is_equal(3)


func test_hp_threshold_damage_reduction_returns_reduction():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 3, &"hp_threshold_damage_reduction", {"threshold": 11, "damage_reduction": 2})
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 1)
	state.set_enemy_hp(11)
	assert_int(ai.get_enemy_damage_reduction(enemy, state)).is_equal(2)


func test_hp_threshold_damage_reduction_returns_zero_when_high_hp():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 3, &"hp_threshold_damage_reduction", {"threshold": 11, "damage_reduction": 2})
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 1)
	state.set_enemy_hp(12)
	assert_int(ai.get_enemy_damage_reduction(enemy, state)).is_equal(0)


func test_hp_threshold_heal_once_triggers_emergency_heal():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(41, 1, &"hp_threshold_heal_once", {"threshold": 15, "heal_amount": 15})
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 1)
	state.set_enemy_hp(15)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.is_emergency_heal).is_true()
	assert_int(action.self_heal).is_equal(15)


func test_hp_threshold_heal_once_does_not_repeat():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(41, 1, &"hp_threshold_heal_once", {"threshold": 15, "heal_amount": 15})
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD, 1)
	state.set_enemy_hp(15)
	state.set_boss_emergency_heal_used(true)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.is_emergency_heal).is_false()

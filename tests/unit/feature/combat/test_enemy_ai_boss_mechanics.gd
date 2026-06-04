extends GdUnitTestSuite


func _make_enemy(hp: int, atk: int, mechanic: StringName = &"", params: Dictionary = {}) -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"test_boss"
	enemy.base_hp = hp
	enemy.base_attack = atk
	enemy.special_mechanic_id = mechanic
	enemy.mechanic_params = params
	return enemy


func _make_combat_state(enemy: EnemyData, round_num: int = 1) -> CombatState:
	var state := CombatState.new()
	state.initialize(enemy, GameEnums.EnemyType.BOSS)
	state.start_round(round_num)
	return state


func test_boss_emergency_heal_triggers_at_half_hp():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(80, 4)
	var state := _make_combat_state(enemy)
	state.set_enemy_hp(40)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.is_emergency_heal).is_true()
	assert_int(action.self_heal).is_equal(24)


func test_boss_emergency_heal_does_not_repeat():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(80, 4)
	var state := _make_combat_state(enemy)
	state.set_enemy_hp(40)
	state.set_boss_emergency_heal_used(true)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.is_emergency_heal).is_false()


func test_sorrow_heals_per_turn():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(80, 4, &"heal_per_turn", {"heal": 5})
	var state := _make_combat_state(enemy)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.self_heal).is_equal(5)
	assert_bool(action.is_emergency_heal).is_false()


func test_envy_self_damage_and_attack_up():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(130, 5, &"self_damage_attack_up", {"self_damage": 6, "attack_bonus": 1})
	var state := _make_combat_state(enemy)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.self_damage).is_equal(6)
	assert_int(action.damage_to_player).is_equal(6)


func test_hatred_tier1_attack_up():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(190, 6, &"hp_tiered_attack_up", {"tier1_hp": 140, "tier1_bonus": 1, "tier2_hp": 80, "tier2_bonus": 2, "tier3_hp": 20, "tier3_bonus": 3})
	var state := _make_combat_state(enemy)
	state.set_enemy_hp(140)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.damage_to_player).is_equal(7)


func test_hatred_tier2_attack_up():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(190, 6, &"hp_tiered_attack_up", {"tier1_hp": 140, "tier1_bonus": 1, "tier2_hp": 80, "tier2_bonus": 2, "tier3_hp": 20, "tier3_bonus": 3})
	var state := _make_combat_state(enemy)
	state.set_enemy_hp(80)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.damage_to_player).is_equal(8)


func test_hatred_tier3_attack_up():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(190, 6, &"hp_tiered_attack_up", {"tier1_hp": 140, "tier1_bonus": 1, "tier2_hp": 80, "tier2_bonus": 2, "tier3_hp": 20, "tier3_bonus": 3})
	var state := _make_combat_state(enemy)
	state.set_enemy_hp(20)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.damage_to_player).is_equal(9)


func test_numbness_skips_player_turn_at_tier1():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(240, 6, &"skip_player_turn", {"tier1_hp": 160, "tier2_hp": 80})
	var state := _make_combat_state(enemy)
	state.set_enemy_hp(160)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.skip_next_player_turn).is_true()


func test_numbness_skips_player_turn_at_tier2():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(240, 6, &"skip_player_turn", {"tier1_hp": 160, "tier2_hp": 80})
	var state := _make_combat_state(enemy)
	state.set_enemy_hp(80)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.skip_next_player_turn).is_true()


func test_numbness_no_skip_when_high_hp():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(240, 6, &"skip_player_turn", {"tier1_hp": 160, "tier2_hp": 80})
	var state := _make_combat_state(enemy)
	state.set_enemy_hp(161)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.skip_next_player_turn).is_false()


func test_origin_combined_heal_and_tiered_attack():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(300, 7, &"heal_per_turn", {"heal": 7, "tier1_hp": 180, "tier1_bonus": 1, "tier2_hp": 100, "tier2_bonus": 2, "tier3_hp": 50, "tier3_bonus": 3})
	var state := _make_combat_state(enemy)
	state.set_enemy_hp(100)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.self_heal).is_equal(7)
	assert_int(action.damage_to_player).is_equal(9)

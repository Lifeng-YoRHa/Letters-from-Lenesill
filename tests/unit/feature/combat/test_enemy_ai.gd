extends GdUnitTestSuite


func _make_enemy(hp: int, atk: int) -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"test_enemy"
	enemy.base_hp = hp
	enemy.base_attack = atk
	return enemy


func _make_combat_state(enemy: EnemyData, encounter_type: GameEnums.EnemyType) -> CombatState:
	var state := CombatState.new()
	state.initialize(enemy, encounter_type)
	return state


func test_normal_enemy_deals_base_attack_damage():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 4)
	var state := _make_combat_state(enemy, GameEnums.EnemyType.NORMAL)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.damage_to_player).is_equal(4)
	assert_int(action.attack_count).is_equal(1)
	assert_bool(action.is_emergency_heal).is_false()


func test_boss_deals_base_attack_damage():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(80, 5)
	enemy.id = &"sorrow"
	var state := _make_combat_state(enemy, GameEnums.EnemyType.BOSS)
	state.set_enemy_hp(60)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.damage_to_player).is_equal(5)
	assert_bool(action.is_emergency_heal).is_false()


func test_boss_emergency_heal_triggers_at_half_hp():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(80, 4)
	enemy.id = &"sorrow"
	var state := _make_combat_state(enemy, GameEnums.EnemyType.BOSS)
	state.set_enemy_hp(40)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.is_emergency_heal).is_true()
	assert_int(action.self_heal).is_equal(24)
	assert_int(action.damage_to_player).is_equal(0)


func test_boss_emergency_heal_does_not_repeat():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(80, 4)
	enemy.id = &"sorrow"
	var state := _make_combat_state(enemy, GameEnums.EnemyType.BOSS)
	state.set_enemy_hp(40)
	state.set_boss_emergency_heal_used(true)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.is_emergency_heal).is_false()
	assert_int(action.damage_to_player).is_equal(4)


func test_non_boss_never_uses_emergency_heal():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(20, 3)
	var state := _make_combat_state(enemy, GameEnums.EnemyType.HARD)
	state.set_enemy_hp(5)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.is_emergency_heal).is_false()
	assert_int(action.damage_to_player).is_equal(3)


func test_emergency_heal_amount_is_30_percent_max_hp():
	var ai := EnemyAI.new()
	var enemy := _make_enemy(100, 5)
	enemy.id = &"test_boss"
	var state := _make_combat_state(enemy, GameEnums.EnemyType.BOSS)
	state.set_enemy_hp(50)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.is_emergency_heal).is_true()
	assert_int(action.self_heal).is_equal(30)


func test_attack_count_can_be_overridden():
	var ai := _DoubleAttackAI.new()
	var enemy := _make_enemy(20, 3)
	var state := _make_combat_state(enemy, GameEnums.EnemyType.NORMAL)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.attack_count).is_equal(2)
	assert_int(action.damage_to_player).is_equal(3)


func test_attack_power_can_be_overridden():
	var ai := _BoostedAttackAI.new()
	var enemy := _make_enemy(20, 3)
	var state := _make_combat_state(enemy, GameEnums.EnemyType.NORMAL)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.damage_to_player).is_equal(8)


func test_self_heal_can_be_overridden():
	var ai := _SelfHealAI.new()
	var enemy := _make_enemy(20, 3)
	var state := _make_combat_state(enemy, GameEnums.EnemyType.NORMAL)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_int(action.self_heal).is_equal(10)
	assert_int(action.damage_to_player).is_equal(3)


func test_skip_turn_can_be_overridden():
	var ai := _SkipTurnAI.new()
	var enemy := _make_enemy(20, 3)
	var state := _make_combat_state(enemy, GameEnums.EnemyType.NORMAL)
	var action: EnemyAction = ai.decide_turn_action(enemy, state)
	assert_bool(action.skip_next_player_turn).is_true()
	assert_int(action.damage_to_player).is_equal(3)


class _DoubleAttackAI extends EnemyAI:
	func _get_attack_count(_enemy_data: EnemyData, _combat_state: CombatState) -> int:
		return 2


class _BoostedAttackAI extends EnemyAI:
	func _get_attack_power(enemy_data: EnemyData, _combat_state: CombatState) -> int:
		return enemy_data.base_attack + 5


class _SelfHealAI extends EnemyAI:
	func _get_self_heal(_enemy_data: EnemyData, _combat_state: CombatState) -> int:
		return 10


class _SkipTurnAI extends EnemyAI:
	func _should_skip_player_turn(_enemy_data: EnemyData, _combat_state: CombatState) -> bool:
		return true

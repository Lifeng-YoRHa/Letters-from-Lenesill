extends GdUnitTestSuite


func _make_combat_state() -> CombatState:
	var enemy := EnemyData.new()
	enemy.id = &"test_enemy"
	enemy.base_hp = 20
	enemy.base_attack = 5
	var state := CombatState.new()
	state.initialize(enemy, GameEnums.EnemyType.NORMAL)
	return state


func test_base_damage_without_modifiers():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	var dmg: int = calc.calculate_player_damage(3, state)
	assert_int(dmg).is_equal(3)


func test_weapon_attack_uses_weapon_attack_value():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	var weapon := WeaponData.new()
	weapon.id = &"test_weapon"
	weapon.attack = 7
	var dmg: int = calc.calculate_player_damage(weapon.attack, state)
	assert_int(dmg).is_equal(7)


func test_courage_active_adds_2_damage():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	state.set_courage_active(true)
	var dmg: int = calc.calculate_player_damage(3, state)
	assert_int(dmg).is_equal(5)


func test_cowardice_debuff_reduces_by_2():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	state.add_debuff(GameEnums.DebuffType.COWARDICE)
	var dmg: int = calc.calculate_player_damage(5, state)
	assert_int(dmg).is_equal(3)


func test_madness_debuff_adds_1_damage():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	state.add_debuff(GameEnums.DebuffType.MADNESS)
	var dmg: int = calc.calculate_player_damage(3, state)
	assert_int(dmg).is_equal(4)


func test_relic_bonus_and_enemy_reduction_applied():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	var dmg: int = calc.calculate_player_damage(5, state, 2, 3)
	assert_int(dmg).is_equal(6)


func test_combined_modifiers_calculate_correctly():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	state.set_courage_active(true)
	state.add_debuff(GameEnums.DebuffType.COWARDICE)
	state.add_debuff(GameEnums.DebuffType.MADNESS)
	var dmg: int = calc.calculate_player_damage(3, state, 2, 3)
	# 3 base + 2 courage + 3 relic - 2 cowardice + 1 madness - 2 reduction = 5
	assert_int(dmg).is_equal(5)


func test_damage_clamped_at_minimum_1():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	state.add_debuff(GameEnums.DebuffType.COWARDICE)
	var dmg: int = calc.calculate_player_damage(1, state, 5)
	# 1 base - 2 cowardice - 5 reduction = -6, clamped to 1
	assert_int(dmg).is_equal(1)


func test_delirium_triggered_deals_zero():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	state.add_debuff(GameEnums.DebuffType.DELIRIUM)
	var dmg: int = calc.calculate_player_damage(10, state, 0, 0, true)
	assert_int(dmg).is_equal(0)


func test_delirium_not_triggered_ignores_debuff():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	state.add_debuff(GameEnums.DebuffType.DELIRIUM)
	var dmg: int = calc.calculate_player_damage(10, state, 0, 0, false)
	assert_int(dmg).is_equal(10)


func test_enemy_damage_without_dodge():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	var dmg: int = calc.calculate_enemy_damage(5, state)
	assert_int(dmg).is_equal(5)


func test_enemy_damage_with_dodge_reduces():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	state.set_dodge_active(true, 4)
	var dmg: int = calc.calculate_enemy_damage(6, state)
	assert_int(dmg).is_equal(2)


func test_enemy_damage_dodge_capped_at_zero():
	var calc := DamageCalculator.new()
	var state := _make_combat_state()
	state.set_dodge_active(true, 6)
	var dmg: int = calc.calculate_enemy_damage(3, state)
	assert_int(dmg).is_equal(0)


func test_last_effort_recovery_calculates_and_caps():
	var calc := DamageCalculator.new()
	assert_int(calc.calculate_last_effort_recovery(0)).is_equal(2)
	assert_int(calc.calculate_last_effort_recovery(1)).is_equal(3)
	assert_int(calc.calculate_last_effort_recovery(2)).is_equal(4)
	assert_int(calc.calculate_last_effort_recovery(5)).is_equal(4)

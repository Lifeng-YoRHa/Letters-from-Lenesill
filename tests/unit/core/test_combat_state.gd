extends GdUnitTestSuite


func _make_enemy(hp: int) -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"test_enemy"
	enemy.base_hp = hp
	enemy.base_attack = 3
	return enemy


func _make_card(id: StringName) -> ActionCardData:
	var card := ActionCardData.new()
	card.id = id
	card.display_name = "Test Card"
	card.stamina_cost = 1
	return card


func test_initialize_sets_enemy_hp_and_phase():
	var state := CombatState.new()
	var enemy := _make_enemy(25)
	state.initialize(enemy, GameEnums.EnemyType.NORMAL)
	assert_int(state.enemy_current_hp).is_equal(25)
	assert_int(state.combat_phase).is_equal(GameEnums.CombatPhase.SETUP)
	assert_int(state.round_number).is_equal(0)
	assert_int(state.actions_used_this_turn).is_equal(0)
	assert_int(state.max_actions_this_turn).is_equal(3)
	assert_bool(state.courage_active).is_false()
	assert_bool(state.dodge_active).is_false()
	assert_bool(state.analyze_active).is_false()
	assert_bool(state.last_effort_used).is_false()
	assert_bool(state.extra_action_next_turn).is_false()
	assert_bool(state.boss_emergency_heal_used).is_false()
	assert_array(state.active_debuffs).is_empty()
	assert_array(state.activated_cards).is_empty()


func test_set_phase_emits_signal():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	var spy := {"new": -1, "old": -1}
	state.phase_changed.connect(func(n: GameEnums.CombatPhase, o: GameEnums.CombatPhase):
		spy["new"] = n
		spy["old"] = o
	)
	state.set_phase(GameEnums.CombatPhase.PLAYER_TURN)
	assert_int(state.combat_phase).is_equal(GameEnums.CombatPhase.PLAYER_TURN)
	assert_int(spy["new"]).is_equal(GameEnums.CombatPhase.PLAYER_TURN)
	assert_int(spy["old"]).is_equal(GameEnums.CombatPhase.SETUP)


func test_start_round_increments_and_resets_actions():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	state.set_actions_used(2)
	var spy := {"round": -1}
	state.round_started.connect(func(r: int):
		spy["round"] = r
	)
	state.start_round(3)
	assert_int(state.round_number).is_equal(3)
	assert_int(state.actions_used_this_turn).is_equal(0)
	assert_int(spy["round"]).is_equal(3)


func test_damage_enemy_reduces_hp_and_emits_signal():
	var state := CombatState.new()
	state.initialize(_make_enemy(20), GameEnums.EnemyType.NORMAL)
	var spy := {"new": -1, "old": -1}
	state.enemy_hp_changed.connect(func(n: int, o: int):
		spy["new"] = n
		spy["old"] = o
	)
	var result: int = state.damage_enemy(7)
	assert_int(result).is_equal(13)
	assert_int(state.enemy_current_hp).is_equal(13)
	assert_int(spy["new"]).is_equal(13)
	assert_int(spy["old"]).is_equal(20)


func test_set_activated_cards_emits_signal():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	var card := _make_card(&"attack")
	var spy := {"cards": []}
	state.activated_cards_changed.connect(func(cards: Array[ActionCardData]):
		spy["cards"] = cards.duplicate()
	)
	state.set_activated_cards([card])
	assert_int(state.activated_cards.size()).is_equal(1)
	assert_object(state.activated_cards[0]).is_same(card)
	assert_int(spy["cards"].size()).is_equal(1)


func test_set_actions_used_and_max_actions_emit_signal():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	var spy := {"used": -1, "max": -1}
	state.actions_used_changed.connect(func(u: int, m: int):
		spy["used"] = u
		spy["max"] = m
	)
	state.set_max_actions(4)
	assert_int(state.max_actions_this_turn).is_equal(4)
	assert_int(spy["used"]).is_equal(0)
	assert_int(spy["max"]).is_equal(4)
	state.set_actions_used(2)
	assert_int(state.actions_used_this_turn).is_equal(2)
	assert_int(spy["used"]).is_equal(2)
	assert_int(spy["max"]).is_equal(4)


func test_add_debuff_and_remove_debuff_emit_signals():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	var add_spy := {"debuff": -1}
	var remove_spy := {"debuff": -1}
	state.debuff_applied.connect(func(d: GameEnums.DebuffType):
		add_spy["debuff"] = d
	)
	state.debuff_removed.connect(func(d: GameEnums.DebuffType):
		remove_spy["debuff"] = d
	)
	state.add_debuff(GameEnums.DebuffType.BLEEDING)
	assert_array(state.active_debuffs).contains_exactly([GameEnums.DebuffType.BLEEDING])
	assert_int(add_spy["debuff"]).is_equal(GameEnums.DebuffType.BLEEDING)
	state.remove_debuff(GameEnums.DebuffType.BLEEDING)
	assert_array(state.active_debuffs).is_empty()
	assert_int(remove_spy["debuff"]).is_equal(GameEnums.DebuffType.BLEEDING)


func test_courage_dodge_analyze_flags_emit_signals():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	var courage_spy := {"active": false}
	var dodge_spy := {"active": false, "reduction": 0}
	var analyze_spy := {"active": false}
	state.courage_toggled.connect(func(a: bool):
		courage_spy["active"] = a
	)
	state.dodge_toggled.connect(func(a: bool, r: int):
		dodge_spy["active"] = a
		dodge_spy["reduction"] = r
	)
	state.analyze_toggled.connect(func(a: bool):
		analyze_spy["active"] = a
	)
	state.set_courage_active(true)
	assert_bool(state.courage_active).is_true()
	assert_bool(courage_spy["active"]).is_true()
	state.set_dodge_active(true, 6)
	assert_bool(state.dodge_active).is_true()
	assert_int(state.dodge_reduction).is_equal(6)
	assert_bool(dodge_spy["active"]).is_true()
	assert_int(dodge_spy["reduction"]).is_equal(6)
	state.set_analyze_active(true)
	assert_bool(state.analyze_active).is_true()
	assert_bool(analyze_spy["active"]).is_true()


func test_last_effort_and_extra_action_flags_emit_signals():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	var last_effort_spy := {"used": false}
	var extra_action_spy := {"active": false}
	state.last_effort_toggled.connect(func(u: bool):
		last_effort_spy["used"] = u
	)
	state.extra_action_toggled.connect(func(a: bool):
		extra_action_spy["active"] = a
	)
	state.set_last_effort_used(true)
	assert_bool(state.last_effort_used).is_true()
	assert_bool(last_effort_spy["used"]).is_true()
	state.set_extra_action_next_turn(true)
	assert_bool(state.extra_action_next_turn).is_true()
	assert_bool(extra_action_spy["active"]).is_true()


func test_boss_emergency_heal_flag_emits_signal():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	var spy := {"used": false}
	state.boss_emergency_heal_toggled.connect(func(u: bool):
		spy["used"] = u
	)
	state.set_boss_emergency_heal_used(true)
	assert_bool(state.boss_emergency_heal_used).is_true()
	assert_bool(spy["used"]).is_true()


func test_get_remaining_actions_calculates_correctly():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	state.set_max_actions(5)
	state.set_actions_used(2)
	assert_int(state.get_remaining_actions()).is_equal(3)


func test_initialize_clears_previous_state():
	var state := CombatState.new()
	state.initialize(_make_enemy(10), GameEnums.EnemyType.NORMAL)
	state.set_phase(GameEnums.CombatPhase.PLAYER_TURN)
	state.start_round(2)
	state.set_actions_used(1)
	state.add_debuff(GameEnums.DebuffType.WEAKNESS)
	state.set_courage_active(true)
	state.set_last_effort_used(true)
	state.set_boss_emergency_heal_used(true)
	var enemy2 := _make_enemy(30)
	state.initialize(enemy2, GameEnums.EnemyType.HARD)
	assert_int(state.enemy_current_hp).is_equal(30)
	assert_int(state.combat_phase).is_equal(GameEnums.CombatPhase.SETUP)
	assert_int(state.round_number).is_equal(0)
	assert_int(state.actions_used_this_turn).is_equal(0)
	assert_bool(state.courage_active).is_false()
	assert_bool(state.last_effort_used).is_false()
	assert_bool(state.boss_emergency_heal_used).is_false()
	assert_array(state.active_debuffs).is_empty()

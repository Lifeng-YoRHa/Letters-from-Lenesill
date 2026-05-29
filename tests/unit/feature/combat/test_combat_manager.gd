extends GdUnitTestSuite


func _make_enemy(hp: int, atk: int) -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"test_enemy"
	enemy.base_hp = hp
	enemy.base_attack = atk
	return enemy


func _make_stamina(max_stamina: int) -> Stamina:
	var stamina := Stamina.new()
	stamina.initialize(max_stamina)
	return stamina


func _make_deck(count: int) -> Array[ActionCardData]:
	var deck: Array[ActionCardData] = []
	for i in range(count):
		var card := ActionCardData.new()
		card.id = StringName("card_" + str(i))
		card.display_name = "Card " + str(i)
		card.stamina_cost = 1
		card.effect = GameEnums.ActionCardEffect.UNARMED_ATTACK
		card.base_value = 3
		deck.append(card)
	return deck


func _make_manager(
	enemy: EnemyData,
	stamina: Stamina,
	deck: Array[ActionCardData],
	encounter_type: GameEnums.EnemyType = GameEnums.EnemyType.NORMAL,
	enemy_ai: EnemyAI = null,
	damage_calc: DamageCalculator = null,
	activated_count: int = 3,
	rng: RandomNumberGenerator = null
) -> CombatManager:
	var manager := CombatManager.new()
	manager.initialize(enemy, encounter_type, stamina, deck, enemy_ai, damage_calc, activated_count, rng)
	return manager


func test_initialize_creates_combat_state():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	assert_object(manager.combat_state).is_not_null()
	assert_int(manager.combat_state.enemy_current_hp).is_equal(20)
	assert_int(manager.combat_state.combat_phase).is_equal(GameEnums.CombatPhase.SETUP)


func test_start_combat_emits_signals():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var started := {"emitted": false}
	manager.combat_started.connect(func(): started.emitted = true)
	var round_spy := {"round": 0}
	manager.round_started.connect(func(r: int): round_spy.round = r)

	manager.start_combat()

	assert_bool(started.emitted).is_true()
	assert_int(round_spy.round).is_equal(1)


func test_start_combat_starts_player_turn():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var turn_started := {"emitted": false}
	manager.player_turn_started.connect(func(_cards): turn_started.emitted = true)

	manager.start_combat()

	assert_int(manager.combat_state.combat_phase).is_equal(GameEnums.CombatPhase.PLAYER_TURN)
	assert_bool(turn_started.emitted).is_true()


func test_start_player_turn_returns_activated_cards():
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck, GameEnums.EnemyType.NORMAL, null, null, 3, rng)

	manager.start_combat()
	var activated := manager.start_player_turn()

	assert_int(activated.size()).is_equal(3)
	assert_int(manager.combat_state.activated_cards.size()).is_equal(3)


func test_start_player_turn_resets_actions():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	manager.start_combat()
	manager.consume_action()
	manager.consume_action()
	manager.consume_action()

	manager.start_player_turn()

	assert_int(manager.get_remaining_actions()).is_equal(3)


func test_consume_action_reduces_remaining():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	manager.start_combat()
	var spy := {"used": 0, "max": 0}
	manager.action_consumed.connect(func(u: int, m: int): spy.used = u; spy.max = m)

	assert_bool(manager.consume_action()).is_true()
	assert_int(manager.get_remaining_actions()).is_equal(2)
	assert_int(spy.used).is_equal(1)
	assert_int(spy.max).is_equal(3)


func test_consume_action_returns_false_when_exhausted():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	manager.start_combat()
	manager.consume_action()
	manager.consume_action()
	manager.consume_action()

	assert_bool(manager.consume_action()).is_false()
	assert_int(manager.get_remaining_actions()).is_equal(0)


func test_end_player_turn_switches_to_enemy_turn():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var spy := {"emitted": false}
	manager.enemy_turn_started.connect(func(): spy.emitted = true)

	manager.start_combat()
	manager.end_player_turn()

	assert_int(manager.combat_state.combat_phase).is_equal(GameEnums.CombatPhase.ENEMY_TURN)
	assert_bool(spy.emitted).is_true()


func test_resolve_enemy_turn_deals_damage():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var dmg_spy := {"amount": 0, "remaining": 0}
	manager.player_took_damage.connect(func(a: int, r: int): dmg_spy.amount = a; dmg_spy.remaining = r)

	manager.start_combat()
	manager.end_player_turn()
	manager.resolve_enemy_turn()

	assert_int(dmg_spy.amount).is_equal(4)
	assert_int(dmg_spy.remaining).is_equal(6)


func test_resolve_enemy_turn_advances_round():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var round_spy := {"round": 0}
	manager.round_started.connect(func(r: int): round_spy.round = r)

	manager.start_combat()
	manager.end_player_turn()
	manager.resolve_enemy_turn()

	assert_int(round_spy.round).is_equal(2)


func test_deal_damage_to_enemy_reduces_hp():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var spy := {"amount": 0, "hp": 0}
	manager.enemy_took_damage.connect(func(a: int, h: int): spy.amount = a; spy.hp = h)

	manager.start_combat()
	manager.deal_damage_to_enemy(5)

	assert_int(spy.amount).is_equal(5)
	assert_int(spy.hp).is_equal(15)
	assert_int(manager.combat_state.enemy_current_hp).is_equal(15)


func test_deal_damage_to_enemy_triggers_victory():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var spy := {"result": -1}
	manager.combat_ended.connect(func(r: GameEnums.CombatPhase): spy.result = r)

	manager.start_combat()
	manager.deal_damage_to_enemy(20)

	assert_int(spy.result).is_equal(GameEnums.CombatPhase.VICTORY)
	assert_bool(manager.is_combat_active()).is_false()


func test_apply_damage_to_player_reduces_stamina():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var spy := {"amount": 0, "remaining": 0}
	manager.player_took_damage.connect(func(a: int, r: int): spy.amount = a; spy.remaining = r)

	manager.start_combat()
	manager.apply_damage_to_player(3)

	assert_int(spy.amount).is_equal(3)
	assert_int(spy.remaining).is_equal(7)


func test_apply_damage_to_player_triggers_defeat():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var spy := {"result": -1}
	manager.combat_ended.connect(func(r: GameEnums.CombatPhase): spy.result = r)

	manager.start_combat()
	manager.apply_damage_to_player(10)

	assert_int(spy.result).is_equal(GameEnums.CombatPhase.DEFEAT)
	assert_bool(manager.is_combat_active()).is_false()


func test_flee_ends_combat():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var spy := {"result": -1}
	manager.combat_ended.connect(func(r: GameEnums.CombatPhase): spy.result = r)

	manager.start_combat()
	manager.flee()

	assert_int(spy.result).is_equal(GameEnums.CombatPhase.FLED)
	assert_bool(manager.is_combat_active()).is_false()


func test_check_defeat_if_no_victory_triggers_defeat():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var spy := {"result": -1}
	manager.combat_ended.connect(func(r: GameEnums.CombatPhase): spy.result = r)

	manager.start_combat()
	stamina.deduct(10)
	manager.check_defeat_if_no_victory()

	assert_int(spy.result).is_equal(GameEnums.CombatPhase.DEFEAT)


func test_check_defeat_does_nothing_when_stamina_positive():
	var enemy := _make_enemy(20, 4)
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	var spy := {"emitted": false}
	manager.combat_ended.connect(func(_r): spy.emitted = true)

	manager.start_combat()
	stamina.deduct(5)
	manager.check_defeat_if_no_victory()

	assert_bool(spy.emitted).is_false()
	assert_bool(manager.is_combat_active()).is_true()


func test_boss_emergency_heal_triggers_on_enemy_turn():
	var enemy := _make_enemy(80, 4)
	var stamina := _make_stamina(20)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck, GameEnums.EnemyType.BOSS)

	manager.start_combat()
	manager.combat_state.set_enemy_hp(40)

	manager.end_player_turn()
	manager.resolve_enemy_turn()

	assert_int(manager.combat_state.enemy_current_hp).is_equal(64)
	assert_bool(manager.is_combat_active()).is_true()
	assert_int(manager.combat_state.combat_phase).is_equal(GameEnums.CombatPhase.PLAYER_TURN)

extends GdUnitTestSuite


func _make_enemy(hp: int, atk: int, mechanic: StringName = &"", params: Dictionary = {}) -> EnemyData:
	var enemy := EnemyData.new()
	enemy.id = &"test_enemy"
	enemy.base_hp = hp
	enemy.base_attack = atk
	enemy.special_mechanic_id = mechanic
	enemy.mechanic_params = params
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
	enemy_ai: EnemyAI = null
) -> CombatManager:
	var manager := CombatManager.new()
	manager.initialize(enemy, GameEnums.EnemyType.BOSS, stamina, deck, null, enemy_ai, null, 3, null)
	return manager


func test_skip_player_turn_skips_entire_player_turn():
	var enemy := _make_enemy(20, 3, &"skip_player_turn", {})
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	manager.start_combat()
	assert_int(manager.combat_state.round_number).is_equal(1)
	assert_int(manager.combat_state.combat_phase).is_equal(GameEnums.CombatPhase.PLAYER_TURN)

	# End player turn normally
	manager.end_player_turn()
	assert_int(manager.combat_state.combat_phase).is_equal(GameEnums.CombatPhase.ENEMY_TURN)

	# Enemy action resolves
	manager.resolve_enemy_turn()
	# After resolve_enemy_turn, skip_next_player_turn is set but not yet consumed
	assert_bool(manager.combat_state.skip_next_player_turn).is_true()

	# Next round should start directly at enemy turn
	assert_int(manager.combat_state.round_number).is_equal(2)
	assert_int(manager.combat_state.combat_phase).is_equal(GameEnums.CombatPhase.ENEMY_TURN)


func test_skip_player_turn_consumed_after_one_round():
	var enemy := _make_enemy(20, 3, &"skip_player_turn", {})
	var stamina := _make_stamina(10)
	var deck := _make_deck(8)
	var manager := _make_manager(enemy, stamina, deck)

	manager.start_combat()
	manager.end_player_turn()
	manager.resolve_enemy_turn()

	# Round 2 skipped player turn
	assert_int(manager.combat_state.round_number).is_equal(2)
	assert_int(manager.combat_state.combat_phase).is_equal(GameEnums.CombatPhase.ENEMY_TURN)

	# Resolve enemy turn again
	manager.resolve_enemy_turn()

	# Round 3 should be normal player turn
	assert_int(manager.combat_state.round_number).is_equal(3)
	assert_int(manager.combat_state.combat_phase).is_equal(GameEnums.CombatPhase.PLAYER_TURN)

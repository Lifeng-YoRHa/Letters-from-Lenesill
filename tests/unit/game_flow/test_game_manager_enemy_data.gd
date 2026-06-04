extends GdUnitTestSuite


func _make_game_manager(chapter: int = 1) -> GameManager:
	var gm := GameManager.new()
	gm.current_chapter = chapter
	gm.rng = RandomNumberGenerator.new()
	gm.rng.seed = 42
	gm.event_manager = EventManager.new()
	var backpack := BackpackManager.new()
	backpack.initialize()
	var relics := RelicHandler.new()
	relics.initialize()
	gm.event_manager.initialize(gm.rng, backpack, relics)
	return gm


func test_normal_enemy_no_longer_fixed_14_4():
	var gm := _make_game_manager(1)
	var seen_variation := false
	var first_hp := -1
	var first_attack := -1

	for i in range(50):
		var enemy := gm._get_enemy_data(GameEnums.EnemyType.NORMAL)
		if i == 0:
			first_hp = enemy.base_hp
			first_attack = enemy.base_attack
		elif enemy.base_hp != first_hp or enemy.base_attack != first_attack:
			seen_variation = true
			break

	assert_bool(seen_variation).is_true()
	gm.queue_free()


func test_hard_enemy_no_longer_fixed_20_6():
	var gm := _make_game_manager(1)
	var seen_variation := false
	var first_hp := -1
	var first_attack := -1

	for i in range(50):
		var enemy := gm._get_enemy_data(GameEnums.EnemyType.HARD)
		if i == 0:
			first_hp = enemy.base_hp
			first_attack = enemy.base_attack
		elif enemy.base_hp != first_hp or enemy.base_attack != first_attack:
			seen_variation = true
			break

	assert_bool(seen_variation).is_true()
	gm.queue_free()


func test_boss_enemy_stays_fixed():
	var gm := _make_game_manager(1)
	var enemy := gm._get_enemy_data(GameEnums.EnemyType.BOSS)
	assert_int(enemy.base_hp).is_equal(50)
	assert_int(enemy.base_attack).is_equal(10)
	gm.queue_free()


func test_hard_enemy_has_special_mechanic_id():
	var gm := _make_game_manager(1)
	var found_mechanic := false
	for i in range(100):
		var enemy := gm._get_enemy_data(GameEnums.EnemyType.HARD)
		if enemy.special_mechanic_id != &"":
			found_mechanic = true
			break
	assert_bool(found_mechanic).is_true()
	gm.queue_free()


func test_chapter_progression_increases_stats():
	var gm_ch1 := _make_game_manager(1)
	var gm_ch5 := _make_game_manager(5)

	var ch1_hps: Array[int] = []
	var ch5_hps: Array[int] = []

	for i in range(100):
		ch1_hps.append(gm_ch1._get_enemy_data(GameEnums.EnemyType.NORMAL).base_hp)
		ch5_hps.append(gm_ch5._get_enemy_data(GameEnums.EnemyType.NORMAL).base_hp)

	var ch1_avg := _avg(ch1_hps)
	var ch5_avg := _avg(ch5_hps)

	assert_int(ch5_avg).is_greater(ch1_avg)
	gm_ch1.queue_free()
	gm_ch5.queue_free()


func _avg(arr: Array[int]) -> int:
	if arr.is_empty():
		return 0
	var sum := 0
	for v in arr:
		sum += v
	return sum / arr.size()

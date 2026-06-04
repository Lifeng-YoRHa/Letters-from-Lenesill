extends GdUnitTestSuite


func _make_manager(rng: RandomNumberGenerator = null) -> EventManager:
	var manager := EventManager.new()
	var backpack := BackpackManager.new()
	backpack.initialize()
	var relics := RelicHandler.new()
	relics.initialize()
	manager.initialize(rng if rng != null else RandomNumberGenerator.new(), backpack, relics)
	return manager


# === Normal Combat: Chapter 1 ===

func test_normal_combat_chapter1_distribution():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {
		"11/3": 0, "14/2": 0, "17/1": 0, "19/1": 0,
	}
	var iterations := 5000

	for i in range(iterations):
		var stats := manager.generate_enemy_stats(GameEnums.EnemyType.NORMAL, 1)
		var key := "%d/%d" % [stats.hp, stats.attack]
		counts[key] = counts.get(key, 0) + 1

	assert_float(counts["11/3"] / float(iterations)).is_between(0.32, 0.42)
	assert_float(counts["14/2"] / float(iterations)).is_between(0.17, 0.27)
	assert_float(counts["17/1"] / float(iterations)).is_between(0.26, 0.36)
	assert_float(counts["19/1"] / float(iterations)).is_between(0.05, 0.15)


# === Normal Combat: Chapter 5 ===

func test_normal_combat_chapter5_distribution():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {
		"30/10": 0, "39/7": 0, "45/5": 0, "52/3": 0, "81/1": 0,
	}
	var iterations := 5000

	for i in range(iterations):
		var stats := manager.generate_enemy_stats(GameEnums.EnemyType.NORMAL, 5)
		var key := "%d/%d" % [stats.hp, stats.attack]
		counts[key] = counts.get(key, 0) + 1

	assert_float(counts["30/10"] / float(iterations)).is_between(0.14, 0.24)
	assert_float(counts["39/7"] / float(iterations)).is_between(0.18, 0.28)
	assert_float(counts["45/5"] / float(iterations)).is_between(0.22, 0.32)
	assert_float(counts["52/3"] / float(iterations)).is_between(0.15, 0.25)
	assert_float(counts["81/1"] / float(iterations)).is_between(0.06, 0.16)


# === Hard Combat: Chapter 1 ===

func test_hard_combat_chapter1_distribution():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {
		"16/4": 0, "28/3": 0, "33/2": 0, "41/1": 0,
	}
	var iterations := 5000

	for i in range(iterations):
		var stats := manager.generate_enemy_stats(GameEnums.EnemyType.HARD, 1)
		var key := "%d/%d" % [stats.hp, stats.attack]
		counts[key] = counts.get(key, 0) + 1

	assert_float(counts["16/4"] / float(iterations)).is_between(0.17, 0.27)
	assert_float(counts["28/3"] / float(iterations)).is_between(0.22, 0.32)
	assert_float(counts["33/2"] / float(iterations)).is_between(0.26, 0.36)
	assert_float(counts["41/1"] / float(iterations)).is_between(0.15, 0.25)


func test_hard_combat_chapter1_mechanics():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var mechanic_counts := {}
	var iterations := 2000

	for i in range(iterations):
		var stats := manager.generate_enemy_stats(GameEnums.EnemyType.HARD, 1)
		var mech: StringName = stats.mechanic
		mechanic_counts[mech] = mechanic_counts.get(mech, 0) + 1

	assert_int(mechanic_counts.get(&"double_attack_turn2", 0)).is_greater(0)
	assert_int(mechanic_counts.get(&"hp_threshold_attack_up", 0)).is_greater(0)
	assert_int(mechanic_counts.get(&"hp_threshold_heal_once", 0)).is_greater(0)
	assert_int(mechanic_counts.get(&"", 0)).is_greater(0)


# === Hard Combat: Chapter 5 ===

func test_hard_combat_chapter5_distribution():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {
		"40/11": 0, "62/9": 0, "71/6": 0, "82/3": 0, "111/1": 0,
	}
	var iterations := 5000

	for i in range(iterations):
		var stats := manager.generate_enemy_stats(GameEnums.EnemyType.HARD, 5)
		var key := "%d/%d" % [stats.hp, stats.attack]
		counts[key] = counts.get(key, 0) + 1

	assert_float(counts["40/11"] / float(iterations)).is_between(0.14, 0.24)
	assert_float(counts["62/9"] / float(iterations)).is_between(0.18, 0.28)
	assert_float(counts["71/6"] / float(iterations)).is_between(0.22, 0.32)
	assert_float(counts["82/3"] / float(iterations)).is_between(0.15, 0.25)
	assert_float(counts["111/1"] / float(iterations)).is_between(0.06, 0.16)


# === Chapter Clamping ===

func test_chapter_below_1_uses_chapter1_table():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var stats := manager.generate_enemy_stats(GameEnums.EnemyType.NORMAL, 0)
	assert_int(stats.hp).is_between(11, 19)
	assert_int(stats.attack).is_between(1, 3)


func test_chapter_above_5_uses_chapter5_table():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var stats := manager.generate_enemy_stats(GameEnums.EnemyType.NORMAL, 99)
	assert_int(stats.hp).is_between(30, 81)
	assert_int(stats.attack).is_between(1, 10)


# === Boss / Unknown Returns Defaults ===

func test_boss_type_returns_default_stats():
	var manager := _make_manager()
	var stats := manager.generate_enemy_stats(GameEnums.EnemyType.BOSS, 1)
	assert_int(stats.hp).is_equal(14)
	assert_int(stats.attack).is_equal(4)
	assert_str(stats.mechanic).is_equal("")

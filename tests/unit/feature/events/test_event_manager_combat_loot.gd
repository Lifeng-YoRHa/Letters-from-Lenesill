extends GdUnitTestSuite


func _make_manager(rng: RandomNumberGenerator = null) -> EventManager:
	var manager := EventManager.new()
	var backpack := BackpackManager.new()
	backpack.initialize()
	var relics := RelicHandler.new()
	relics.initialize()
	manager.initialize(rng if rng != null else RandomNumberGenerator.new(), backpack, relics)
	return manager


func _make_relic(id: StringName) -> RelicData:
	var r := RelicData.new()
	r.id = id
	r.display_name = str(id)
	return r


# === Gold Distribution: Normal Combat ===

func test_normal_combat_gold_chapter1_distribution():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {3: 0, 4: 0, 5: 0, 6: 0}
	var iterations := 5000

	for i in range(iterations):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.NORMAL, 1, [], [])
		var gold: int = result.gold
		counts[gold] = counts.get(gold, 0) + 1

	assert_float(counts[3] / float(iterations)).is_between(0.12, 0.22)
	assert_float(counts[4] / float(iterations)).is_between(0.43, 0.53)
	assert_float(counts[5] / float(iterations)).is_between(0.15, 0.25)
	assert_float(counts[6] / float(iterations)).is_between(0.10, 0.20)


func test_normal_combat_gold_chapter5_distribution():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {}
	var iterations := 5000

	for i in range(iterations):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.NORMAL, 5, [], [])
		var gold: int = result.gold
		counts[gold] = counts.get(gold, 0) + 1

	assert_float(counts.get(10, 0) / float(iterations)).is_between(0.10, 0.18)
	assert_float(counts.get(12, 0) / float(iterations)).is_between(0.30, 0.38)
	assert_float(counts.get(15, 0) / float(iterations)).is_between(0.00, 0.04)


# === Gold Distribution: Hard Combat ===

func test_hard_combat_gold_chapter1_distribution():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {7: 0, 8: 0, 9: 0, 10: 0, 11: 0}
	var iterations := 5000

	for i in range(iterations):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.HARD, 1, [], [])
		var gold: int = result.gold
		counts[gold] = counts.get(gold, 0) + 1

	assert_float(counts[7] / float(iterations)).is_between(0.12, 0.22)
	assert_float(counts[8] / float(iterations)).is_between(0.43, 0.53)
	assert_float(counts[9] / float(iterations)).is_between(0.15, 0.25)
	assert_float(counts[10] / float(iterations)).is_between(0.08, 0.16)
	assert_float(counts[11] / float(iterations)).is_between(0.00, 0.06)


# === Consumable Count: Normal vs Hard ===

func test_normal_combat_consumable_count_chapter1():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {1: 0, 2: 0, 3: 0}
	var iterations := 5000

	for i in range(iterations):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.NORMAL, 1, [], [])
		var items: Array[ItemData] = result.items
		var consumable_count := 0
		for item in items:
			if item.item_type == GameEnums.ItemType.CONSUMABLE:
				consumable_count += 1
		counts[consumable_count] = counts.get(consumable_count, 0) + 1

	assert_float(counts[1] / float(iterations)).is_between(0.45, 0.55)
	assert_float(counts[2] / float(iterations)).is_between(0.35, 0.45)
	assert_float(counts[3] / float(iterations)).is_between(0.05, 0.15)


func test_hard_combat_consumable_count_chapter1():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {1: 0, 2: 0, 3: 0}
	var iterations := 5000

	for i in range(iterations):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.HARD, 1, [], [])
		var items: Array[ItemData] = result.items
		var consumable_count := 0
		for item in items:
			if item.item_type == GameEnums.ItemType.CONSUMABLE:
				consumable_count += 1
		counts[consumable_count] = counts.get(consumable_count, 0) + 1

	assert_float(counts[1] / float(iterations)).is_between(0.30, 0.40)
	assert_float(counts[2] / float(iterations)).is_between(0.40, 0.50)
	assert_float(counts[3] / float(iterations)).is_between(0.15, 0.25)


# === Consumable Type Distribution ===

func test_normal_combat_consumable_type_chapter1():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {
		&"stone": 0, &"whetstone": 0, &"energy_drink": 0,
		&"flashlight": 0, &"torch": 0, &"safe_house_key": 0,
	}
	var iterations := 5000

	for i in range(iterations):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.NORMAL, 1, [], [])
		var items: Array[ItemData] = result.items
		for item in items:
			if item.item_type == GameEnums.ItemType.CONSUMABLE:
				counts[item.id] = counts.get(item.id, 0) + 1

	var total := iterations * 1.9  # approx avg ~1.9 consumables per fight
	assert_float(counts[&"stone"] / total).is_between(0.14, 0.24)
	assert_float(counts[&"whetstone"] / total).is_between(0.18, 0.28)
	assert_float(counts[&"energy_drink"] / total).is_between(0.30, 0.40)
	assert_float(counts[&"safe_house_key"] / total).is_between(0.02, 0.06)


# === Relic Distribution: Hard Combat Only ===

func test_hard_combat_relic_count_chapter1():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {0: 0, 1: 0}
	var iterations := 5000

	for i in range(iterations):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.HARD, 1, [&"cross", &"badge"], [])
		var relic_count := 0
		var items: Array[ItemData] = result.items
		for item in items:
			if item.item_type == GameEnums.ItemType.RELIC:
				relic_count += 1
		counts[relic_count] = counts.get(relic_count, 0) + 1

	assert_float(counts[0] / float(iterations)).is_between(0.75, 0.85)
	assert_float(counts[1] / float(iterations)).is_between(0.15, 0.25)


func test_hard_combat_relic_count_chapter5():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {0: 0, 1: 0, 2: 0}
	var iterations := 5000

	for i in range(iterations):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.HARD, 5, [&"cross", &"badge", &"mp4"], [])
		var relic_count := 0
		var items: Array[ItemData] = result.items
		for item in items:
			if item.item_type == GameEnums.ItemType.RELIC:
				relic_count += 1
		counts[relic_count] = counts.get(relic_count, 0) + 1

	assert_float(counts[0] / float(iterations)).is_between(0.43, 0.53)
	assert_float(counts[1] / float(iterations)).is_between(0.45, 0.55)
	assert_float(counts[2] / float(iterations)).is_between(0.00, 0.04)


# === Relic Filtering ===

func test_no_relics_if_all_unlocked_already_held():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var held := [_make_relic(&"cross"), _make_relic(&"badge")]
	for i in range(100):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.HARD, 5, [&"cross", &"badge"], held)
		var items: Array[ItemData] = result.items
		for item in items:
			assert_int(item.item_type).is_not_equal(GameEnums.ItemType.RELIC)


func test_no_relics_if_no_unlocked_relics():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	for i in range(100):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.HARD, 1, [], [])
		var items: Array[ItemData] = result.items
		for item in items:
			assert_int(item.item_type).is_not_equal(GameEnums.ItemType.RELIC)


# === Normal Combat Never Drops Relics ===

func test_normal_combat_never_drops_relics():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	for i in range(200):
		var result := manager.resolve_combat_loot(GameEnums.EnemyType.NORMAL, 5, [&"cross", &"badge", &"mp4", &"coin_purse"], [])
		var items: Array[ItemData] = result.items
		for item in items:
			assert_int(item.item_type).is_not_equal(GameEnums.ItemType.RELIC)


# === Chapter Clamping ===

func test_chapter_below_1_uses_chapter1_table():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var result_low := manager.resolve_combat_loot(GameEnums.EnemyType.NORMAL, 0, [], [])
	var result_high := manager.resolve_combat_loot(GameEnums.EnemyType.NORMAL, 1, [], [])

	# Both should follow chapter 1 ranges (gold 3-6 for normal)
	assert_int(result_low.gold).is_between(3, 6)
	assert_int(result_high.gold).is_between(3, 6)


func test_chapter_above_5_uses_chapter5_table():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var result := manager.resolve_combat_loot(GameEnums.EnemyType.NORMAL, 99, [], [])
	# Chapter 5 normal gold range is 10-15
	assert_int(result.gold).is_between(10, 15)

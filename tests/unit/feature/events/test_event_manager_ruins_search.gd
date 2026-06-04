extends GdUnitTestSuite


func _make_manager(rng: RandomNumberGenerator = null) -> EventManager:
	var manager := EventManager.new()
	var backpack := BackpackManager.new()
	backpack.initialize()
	var relics := RelicHandler.new()
	relics.initialize()
	manager.initialize(rng if rng != null else RandomNumberGenerator.new(), backpack, relics)
	return manager


func _make_weapon(id: StringName, chapter: int) -> WeaponData:
	var w := WeaponData.new()
	w.id = id
	w.display_name = str(id)
	w.attack = 5
	w.max_durability = 3
	w.size = Vector2i(1, 2)
	w.unlock_chapter = chapter
	return w


# === Stamina Cost & Exhaustion ===

func test_resolve_ruins_search_first_search_stamina_cost_is_1():
	var manager := _make_manager()
	var result := manager.resolve_ruins_search(0, 1, [], [], [])
	assert_int(result.stamina_cost).is_equal(1)
	assert_bool(result.exhausted).is_false()


func test_resolve_ruins_search_second_search_stamina_cost_is_2():
	var manager := _make_manager()
	var result := manager.resolve_ruins_search(1, 1, [], [], [])
	assert_int(result.stamina_cost).is_equal(2)
	assert_bool(result.exhausted).is_false()


func test_resolve_ruins_search_third_search_stamina_cost_is_3_and_exhausted():
	var manager := _make_manager()
	var result := manager.resolve_ruins_search(2, 1, [], [], [])
	assert_int(result.stamina_cost).is_equal(3)
	assert_bool(result.exhausted).is_true()


# === Probability Distribution: 1st Search ===

func test_first_search_distribution_matches_design():
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var manager := _make_manager(rng)

	var counts := {
		"gold_7": 0, "gold_13": 0, "gold_20": 0,
		"consumable": 0, "safe_house_key": 0, "relic": 0,
	}
	var iterations := 10000

	for i in range(iterations):
		var result := manager.resolve_ruins_search(0, 1, [&"cross"], [], [])
		var gold: int = result.gold
		var items: Array[ItemData] = result.items
		var bp: StringName = result.backpack_reward

		if gold == 7:
			counts.gold_7 += 1
		elif gold == 13:
			counts.gold_13 += 1
		elif gold == 20:
			counts.gold_20 += 1

		if bp != &"":
			counts.safe_house_key += 1

		for item in items:
			match item.item_type:
				GameEnums.ItemType.CONSUMABLE:
					counts.consumable += 1
				GameEnums.ItemType.RELIC:
					counts.relic += 1
				GameEnums.ItemType.WEAPON:
					pass
				GameEnums.ItemType.BACKPACK:
					pass

	# Gold 7: expected ~17%
	assert_float(counts.gold_7 / float(iterations)).is_between(0.14, 0.20)
	# Gold 13: expected ~13%
	assert_float(counts.gold_13 / float(iterations)).is_between(0.10, 0.16)
	# Gold 20: expected ~3%
	assert_float(counts.gold_20 / float(iterations)).is_between(0.01, 0.06)
	# Consumables: expected 34+21+8 = 63%
	assert_float(counts.consumable / float(iterations)).is_between(0.58, 0.68)
	# Safe house key: expected ~3%
	assert_float(counts.safe_house_key / float(iterations)).is_between(0.01, 0.06)
	# Relic: expected ~1%
	assert_float(counts.relic / float(iterations)).is_between(0.00, 0.03)


# === Probability Distribution: 2nd Search ===

func test_second_search_distribution_matches_design():
	var rng := RandomNumberGenerator.new()
	rng.seed = 123
	var manager := _make_manager(rng)

	var counts := {
		"gold_7": 0, "gold_13": 0, "gold_20": 0,
		"consumable": 0, "safe_house_key": 0, "relic": 0,
		"weapon": 0, "backpack": 0,
	}
	var iterations := 10000
	var weapon := _make_weapon(&"test_weapon", 1)

	for i in range(iterations):
		var result := manager.resolve_ruins_search(1, 1, [&"cross"], [weapon], [&"satchel"])
		var gold: int = result.gold
		var items: Array[ItemData] = result.items
		var bp: StringName = result.backpack_reward

		if gold == 7:
			counts.gold_7 += 1
		elif gold == 13:
			counts.gold_13 += 1
		elif gold == 20:
			counts.gold_20 += 1

		if bp != &"":
			counts.backpack += 1

		for item in items:
			match item.item_type:
				GameEnums.ItemType.CONSUMABLE:
					counts.consumable += 1
				GameEnums.ItemType.RELIC:
					counts.relic += 1
				GameEnums.ItemType.WEAPON:
					counts.weapon += 1
				GameEnums.ItemType.BACKPACK:
					counts.backpack += 1

	# Consumables: expected 10+37+10 = 57%
	assert_float(counts.consumable / float(iterations)).is_between(0.52, 0.62)
	# Gold total: expected 8+17+6 = 31%
	var gold_total := counts.gold_7 + counts.gold_13 + counts.gold_20
	assert_float(gold_total / float(iterations)).is_between(0.26, 0.36)
	# Safe house key: expected ~7%
	# (key is rolled as consumable or direct; we check direct here which is rare)
	# Relic: expected ~3%
	assert_float(counts.relic / float(iterations)).is_between(0.01, 0.06)
	# Weapon: expected ~1%
	assert_float(counts.weapon / float(iterations)).is_between(0.00, 0.03)
	# Backpack: expected ~1%
	assert_float(counts.backpack / float(iterations)).is_between(0.00, 0.03)


# === Probability Distribution: 3rd Search ===

func test_third_search_distribution_matches_design():
	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var manager := _make_manager(rng)

	var counts := {
		"gold_7": 0, "gold_13": 0, "gold_20": 0,
		"consumable": 0, "safe_house_key": 0, "relic": 0,
		"weapon": 0, "backpack": 0,
	}
	var iterations := 10000
	var weapon := _make_weapon(&"test_weapon", 1)

	for i in range(iterations):
		var result := manager.resolve_ruins_search(2, 1, [&"cross"], [weapon], [&"satchel"])
		var gold: int = result.gold
		var items: Array[ItemData] = result.items
		var bp: StringName = result.backpack_reward

		if gold == 7:
			counts.gold_7 += 1
		elif gold == 13:
			counts.gold_13 += 1
		elif gold == 20:
			counts.gold_20 += 1

		if bp != &"":
			counts.backpack += 1

		for item in items:
			match item.item_type:
				GameEnums.ItemType.CONSUMABLE:
					counts.consumable += 1
				GameEnums.ItemType.RELIC:
					counts.relic += 1
				GameEnums.ItemType.WEAPON:
					counts.weapon += 1
				GameEnums.ItemType.BACKPACK:
					counts.backpack += 1

	# Consumables: expected 6+26+21 = 53%
	assert_float(counts.consumable / float(iterations)).is_between(0.48, 0.58)
	# Gold total: expected 3+7+20 = 30%
	var gold_total := counts.gold_7 + counts.gold_13 + counts.gold_20
	assert_float(gold_total / float(iterations)).is_between(0.25, 0.35)
	# Relic: expected ~4%
	assert_float(counts.relic / float(iterations)).is_between(0.02, 0.07)
	# Weapon: expected ~2%
	assert_float(counts.weapon / float(iterations)).is_between(0.00, 0.04)
	# Backpack: expected ~2%
	assert_float(counts.backpack / float(iterations)).is_between(0.00, 0.04)


# === Empty List Handling ===

func test_empty_relic_list_skips_relic_reward():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var manager := _make_manager(rng)

	# Force relic reward by using a fixed RNG that would roll relic
	# Instead, test with empty list: no crash, no items
	var result := manager.resolve_ruins_search(0, 1, [], [], [])
	var items: Array[ItemData] = result.items
	for item in items:
		assert_int(item.item_type).is_not_equal(GameEnums.ItemType.RELIC)


func test_empty_weapon_list_skips_weapon_reward():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var manager := _make_manager(rng)

	for i in range(100):
		var result := manager.resolve_ruins_search(1, 1, [&"cross"], [], [])
		var items: Array[ItemData] = result.items
		for item in items:
			assert_int(item.item_type).is_not_equal(GameEnums.ItemType.WEAPON)


func test_empty_backpack_list_skips_backpack_reward():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var manager := _make_manager(rng)

	for i in range(100):
		var result := manager.resolve_ruins_search(1, 1, [&"cross"], [_make_weapon(&"w", 1)], [])
		assert_string(result.backpack_reward).is_equal("")


# === Consumable Sub-pool ===

func test_consumable_sub_pool_distribution():
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var manager := _make_manager(rng)

	var counts := {
		&"whetstone": 0, &"stone": 0, &"energy_drink": 0,
		&"flashlight": 0, &"torch": 0,
	}
	var iterations := 5000

	for i in range(iterations):
		var result := manager.resolve_ruins_search(0, 1, [], [], [])
		var items: Array[ItemData] = result.items
		for item in items:
			if item.item_type == GameEnums.ItemType.CONSUMABLE:
				counts[item.id] = counts.get(item.id, 0) + 1

	# Whetstone: expected ~23%
	assert_float(counts[&"whetstone"] / float(iterations)).is_between(0.18, 0.28)
	# Stone: expected ~11%
	assert_float(counts[&"stone"] / float(iterations)).is_between(0.07, 0.15)
	# Energy drink: expected ~32%
	assert_float(counts[&"energy_drink"] / float(iterations)).is_between(0.27, 0.37)
	# Flashlight: expected ~16%
	assert_float(counts[&"flashlight"] / float(iterations)).is_between(0.12, 0.20)
	# Torch: expected ~18%
	assert_float(counts[&"torch"] / float(iterations)).is_between(0.14, 0.22)


# === Chapter Filtering ===

func test_weapon_filtered_by_unlock_chapter():
	var rng := RandomNumberGenerator.new()
	rng.seed = 555
	var manager := _make_manager(rng)

	var weapon_ch1 := _make_weapon(&"w1", 1)
	var weapon_ch3 := _make_weapon(&"w3", 3)

	# Chapter 1 should only see w1
	for i in range(100):
		var result := manager.resolve_ruins_search(1, 1, [&"cross"], [weapon_ch1, weapon_ch3], [&"satchel"])
		var items: Array[ItemData] = result.items
		for item in items:
			if item.item_type == GameEnums.ItemType.WEAPON:
				assert_string(item.id).is_equal("w1")

	# Chapter 3 should see both
	var found_w3 := false
	for i in range(200):
		var result := manager.resolve_ruins_search(1, 3, [&"cross"], [weapon_ch1, weapon_ch3], [&"satchel"])
		var items: Array[ItemData] = result.items
		for item in items:
			if item.item_type == GameEnums.ItemType.WEAPON:
				if item.id == &"w3":
					found_w3 = true
	assert_bool(found_w3).is_true()


# === Safe House Key Reward ===

func test_safe_house_key_reward_properties():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1111
	var manager := _make_manager(rng)

	var result := manager.resolve_ruins_search(0, 1, [], [], [])
	var items: Array[ItemData] = result.items
	for item in items:
		if item.id == &"safe_house_key":
			assert_string(item.display_name).is_equal("安全屋房卡")
			assert_int(item.item_type).is_equal(GameEnums.ItemType.CONSUMABLE)
			assert_int(item.width).is_equal(1)
			assert_int(item.height).is_equal(1)

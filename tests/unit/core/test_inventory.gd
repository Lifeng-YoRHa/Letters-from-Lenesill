extends GdUnitTestSuite


func test_initialize_sets_gold():
	var inv := Inventory.new()
	inv.initialize(8)
	assert_int(inv.gold).is_equal(8)


func test_add_gold_increases_and_emits_signal():
	var inv := Inventory.new()
	inv.initialize(8)
	var spy := {"new": -1, "old": -1}
	inv.gold_changed.connect(func(n: int, o: int):
		spy["new"] = n
		spy["old"] = o
	)
	var accepted: int = inv.add_gold(5)
	assert_int(inv.gold).is_equal(13)
	assert_int(accepted).is_equal(5)
	assert_int(spy["new"]).is_equal(13)
	assert_int(spy["old"]).is_equal(8)


func test_add_gold_caps_at_99():
	var inv := Inventory.new()
	inv.initialize(95)
	var accepted: int = inv.add_gold(10)
	assert_int(inv.gold).is_equal(99)
	assert_int(accepted).is_equal(4)


func test_add_gold_zero_or_negative_is_no_op():
	var inv := Inventory.new()
	inv.initialize(8)
	var fired := false
	inv.gold_changed.connect(func(_n: int, _o: int):
		fired = true
	)
	var accepted1: int = inv.add_gold(0)
	var accepted2: int = inv.add_gold(-3)
	assert_int(inv.gold).is_equal(8)
	assert_int(accepted1).is_equal(0)
	assert_int(accepted2).is_equal(0)
	assert_bool(fired).is_false()


func test_remove_gold_decreases_and_emits_signal():
	var inv := Inventory.new()
	inv.initialize(10)
	var spy := {"new": -1, "old": -1}
	inv.gold_changed.connect(func(n: int, o: int):
		spy["new"] = n
		spy["old"] = o
	)
	var removed: int = inv.remove_gold(3)
	assert_int(inv.gold).is_equal(7)
	assert_int(removed).is_equal(3)
	assert_int(spy["new"]).is_equal(7)
	assert_int(spy["old"]).is_equal(10)


func test_remove_gold_does_not_go_below_zero():
	var inv := Inventory.new()
	inv.initialize(5)
	var removed: int = inv.remove_gold(10)
	assert_int(inv.gold).is_equal(0)
	assert_int(removed).is_equal(5)


func test_set_equipped_weapon_emits_signal():
	var inv := Inventory.new()
	var weapon := WeaponData.new()
	weapon.id = &"test_weapon"
	var spy := {"new": null, "old": null}
	inv.equipped_weapon_changed.connect(func(n: WeaponData, o: WeaponData):
		spy["new"] = n
		spy["old"] = o
	)
	inv.set_equipped_weapon(weapon)
	assert_object(inv.equipped_weapon).is_same(weapon)
	assert_object(spy["new"]).is_same(weapon)
	assert_object(spy["old"]).is_null()


func test_add_item_emits_signal():
	var inv := Inventory.new()
	var item := InventoryItem.new()
	item.item_id = &"test_item"
	var spy := {"item": null}
	inv.item_added.connect(func(i: InventoryItem):
		spy["item"] = i
	)
	inv.add_item(item)
	assert_int(inv.get_all_items().size()).is_equal(1)
	assert_object(spy["item"]).is_same(item)


func test_remove_item_emits_signal():
	var inv := Inventory.new()
	var item := InventoryItem.new()
	item.item_id = &"test_item"
	inv.add_item(item)
	var spy := {"item": null}
	inv.item_removed.connect(func(i: InventoryItem):
		spy["item"] = i
	)
	inv.remove_item(item)
	assert_int(inv.get_all_items().size()).is_equal(0)
	assert_object(spy["item"]).is_same(item)


func test_get_pocket_items_and_backpack_items_filter():
	var inv := Inventory.new()
	var pocket0 := InventoryItem.new()
	pocket0.pocket_index = 0
	var pocket1 := InventoryItem.new()
	pocket1.pocket_index = 1
	var backpack := InventoryItem.new()
	backpack.pocket_index = -1
	inv.add_item(pocket0)
	inv.add_item(pocket1)
	inv.add_item(backpack)
	assert_int(inv.get_pocket_items(0).size()).is_equal(1)
	assert_object(inv.get_pocket_items(0)[0]).is_same(pocket0)
	assert_int(inv.get_pocket_items(1).size()).is_equal(1)
	assert_object(inv.get_pocket_items(1)[0]).is_same(pocket1)
	assert_int(inv.get_backpack_items().size()).is_equal(1)
	assert_object(inv.get_backpack_items()[0]).is_same(backpack)


func test_1x1_item_tracked_with_correct_size():
	var inv := Inventory.new()
	var item := InventoryItem.new()
	item.item_id = &"whetstone"
	item.size = Vector2i(1, 1)
	item.is_rotatable = false
	item.position = Vector2i(0, 0)
	item.pocket_index = 0
	inv.add_item(item)
	var retrieved: InventoryItem = inv.get_all_items()[0]
	assert_int(retrieved.size.x).is_equal(1)
	assert_int(retrieved.size.y).is_equal(1)
	assert_bool(retrieved.is_rotatable).is_false()


func test_1x2_item_tracked_with_correct_size():
	var inv := Inventory.new()
	var item := InventoryItem.new()
	item.item_id = &"flashlight"
	item.size = Vector2i(1, 2)
	item.is_rotatable = true
	item.position = Vector2i(2, 3)
	item.pocket_index = -1
	inv.add_item(item)
	var retrieved: InventoryItem = inv.get_all_items()[0]
	assert_int(retrieved.size.x).is_equal(1)
	assert_int(retrieved.size.y).is_equal(2)
	assert_bool(retrieved.is_rotatable).is_true()
	assert_int(retrieved.position.x).is_equal(2)
	assert_int(retrieved.position.y).is_equal(3)


func test_1x2_item_rotation_swaps_dimensions():
	var item := InventoryItem.new()
	item.size = Vector2i(1, 2)
	item.is_rotatable = true
	item.rotate()
	assert_bool(item.is_rotated).is_true()
	assert_int(item.size.x).is_equal(2)
	assert_int(item.size.y).is_equal(1)
	item.rotate()
	assert_bool(item.is_rotated).is_false()
	assert_int(item.size.x).is_equal(1)
	assert_int(item.size.y).is_equal(2)


func test_non_rotatable_item_ignores_rotation():
	var item := InventoryItem.new()
	item.size = Vector2i(2, 2)
	item.is_rotatable = false
	item.rotate()
	assert_bool(item.is_rotated).is_false()
	assert_int(item.size.x).is_equal(2)
	assert_int(item.size.y).is_equal(2)


func test_mixed_size_items_tracked_together():
	var inv := Inventory.new()
	var item_1x1 := InventoryItem.new()
	item_1x1.item_id = &"relic"
	item_1x1.size = Vector2i(1, 1)
	item_1x1.pocket_index = 0
	var item_1x2 := InventoryItem.new()
	item_1x2.item_id = &"torch"
	item_1x2.size = Vector2i(1, 2)
	item_1x2.pocket_index = -1
	var item_2x2 := InventoryItem.new()
	item_2x2.item_id = &"kitchen_knife"
	item_2x2.size = Vector2i(2, 2)
	item_2x2.pocket_index = -1
	inv.add_item(item_1x1)
	inv.add_item(item_1x2)
	inv.add_item(item_2x2)
	assert_int(inv.get_all_items().size()).is_equal(3)
	var total_cells: int = 0
	for item in inv.get_all_items():
		total_cells += item.size.x * item.size.y
	assert_int(total_cells).is_equal(7)

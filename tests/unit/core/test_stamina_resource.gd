extends GdUnitTestSuite


func test_initialize_sets_values():
	var stamina := Stamina.new()
	stamina.initialize(12)
	assert_int(stamina.current_stamina).is_equal(12)
	assert_int(stamina.max_stamina).is_equal(12)


func test_deduct_reduces_stamina_and_emits_signal():
	var stamina := Stamina.new()
	stamina.initialize(12)
	var spy := {"new": -1, "old": -1}
	stamina.stamina_changed.connect(func(n: int, o: int):
		spy["new"] = n
		spy["old"] = o
	)
	stamina.deduct(3)
	assert_int(stamina.current_stamina).is_equal(9)
	assert_int(spy["new"]).is_equal(9)
	assert_int(spy["old"]).is_equal(12)


func test_deduct_to_zero_emits_depleted():
	var stamina := Stamina.new()
	stamina.initialize(3)
	var spy := {"value": 999}
	stamina.stamina_depleted.connect(func(v: int):
		spy["value"] = v
	)
	stamina.deduct(3)
	assert_int(stamina.current_stamina).is_equal(0)
	assert_int(spy["value"]).is_equal(0)


func test_deduct_below_zero_emits_depleted():
	var stamina := Stamina.new()
	stamina.initialize(3)
	var spy := {"value": 999}
	stamina.stamina_depleted.connect(func(v: int):
		spy["value"] = v
	)
	stamina.deduct(5)
	assert_int(stamina.current_stamina).is_equal(-2)
	assert_int(spy["value"]).is_equal(-2)


func test_deduct_zero_or_negative_is_no_op():
	var stamina := Stamina.new()
	stamina.initialize(12)
	var signal_fired := false
	stamina.stamina_changed.connect(func(_n: int, _o: int):
		signal_fired = true
	)
	stamina.deduct(0)
	assert_int(stamina.current_stamina).is_equal(12)
	assert_bool(signal_fired).is_false()
	stamina.deduct(-3)
	assert_int(stamina.current_stamina).is_equal(12)
	assert_bool(signal_fired).is_false()


func test_restore_increases_but_caps_at_max():
	var stamina := Stamina.new()
	stamina.initialize(12)
	stamina.deduct(5)
	var spy := {"new": -1, "old": -1}
	stamina.stamina_changed.connect(func(n: int, o: int):
		spy["new"] = n
		spy["old"] = o
	)
	stamina.restore(3)
	assert_int(stamina.current_stamina).is_equal(10)
	assert_int(spy["new"]).is_equal(10)
	assert_int(spy["old"]).is_equal(7)
	stamina.restore(10)
	assert_int(stamina.current_stamina).is_equal(12)


func test_restore_zero_or_negative_is_no_op():
	var stamina := Stamina.new()
	stamina.initialize(12)
	stamina.deduct(3)
	var signal_fired := false
	stamina.stamina_changed.connect(func(_n: int, _o: int):
		signal_fired = true
	)
	stamina.restore(0)
	assert_int(stamina.current_stamina).is_equal(9)
	assert_bool(signal_fired).is_false()
	stamina.restore(-2)
	assert_int(stamina.current_stamina).is_equal(9)
	assert_bool(signal_fired).is_false()


func test_set_max_increases_without_changing_current():
	var stamina := Stamina.new()
	stamina.initialize(12)
	stamina.deduct(4)
	var max_spy := {"new": -1, "old": -1}
	stamina.max_stamina_changed.connect(func(n: int, o: int):
		max_spy["new"] = n
		max_spy["old"] = o
	)
	stamina.set_max_stamina(16)
	assert_int(stamina.max_stamina).is_equal(16)
	assert_int(stamina.current_stamina).is_equal(8)
	assert_int(max_spy["new"]).is_equal(16)
	assert_int(max_spy["old"]).is_equal(12)


func test_set_max_decrease_truncates_current():
	var stamina := Stamina.new()
	stamina.initialize(12)
	stamina.deduct(2)
	var spy := {"new": -1, "old": -1}
	stamina.stamina_changed.connect(func(n: int, o: int):
		spy["new"] = n
		spy["old"] = o
	)
	stamina.set_max_stamina(8)
	assert_int(stamina.max_stamina).is_equal(8)
	assert_int(stamina.current_stamina).is_equal(8)
	assert_int(spy["new"]).is_equal(8)
	assert_int(spy["old"]).is_equal(10)

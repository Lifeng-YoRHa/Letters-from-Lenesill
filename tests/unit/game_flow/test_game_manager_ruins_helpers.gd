extends GdUnitTestSuite


func test_get_available_backpacks_filters_by_chapter():
	# Arrange
	var gm := GameManager.new()

	# Act
	var ch1 := gm._get_available_backpacks(1)
	var ch2 := gm._get_available_backpacks(2)
	var ch5 := gm._get_available_backpacks(5)

	# Assert
	assert_int(ch1.size()).is_equal(2)  # satchel, student_backpack
	assert_bool(ch1.has(&"satchel")).is_true()
	assert_bool(ch1.has(&"student_backpack")).is_true()

	assert_int(ch2.size()).is_equal(3)  # + travel_backpack
	assert_bool(ch2.has(&"travel_backpack")).is_true()

	assert_int(ch5.size()).is_equal(6)  # all backpacks

	gm.queue_free()


func test_get_available_backpacks_returns_empty_for_chapter_0():
	var gm := GameManager.new()
	var result := gm._get_available_backpacks(0)
	assert_int(result.size()).is_equal(0)
	gm.queue_free()

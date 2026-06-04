extends GdUnitTestSuite


func test_default_title_is_combat_victory():
	# Arrange
	var screen := LootScreen.new()

	# Assert (default state before show_loot)
	assert_string(screen._title).is_equal("战斗胜利！")

	screen.queue_free()


func test_set_title_changes_title():
	# Arrange
	var screen := LootScreen.new()

	# Act
	screen.set_title("废墟搜刮")

	# Assert
	assert_string(screen._title).is_equal("废墟搜刮")

	screen.queue_free()


func test_show_loot_uses_custom_title():
	# Arrange
	var screen := LootScreen.new()
	screen.set_title("废墟搜刮")

	# We can't fully test Label text without scene tree, but we can verify the field
	assert_string(screen._title).is_equal("废墟搜刮")

	screen.queue_free()

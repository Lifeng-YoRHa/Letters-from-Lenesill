extends GdUnitTestSuite


func _make_generator(seed_value: int = 42) -> MapGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var gen := MapGenerator.new()
	gen.initialize(rng)
	return gen


func _count_nodes_by_type(nodes: Array[MapNodeData], type: GameEnums.MapNodeType) -> int:
	var count := 0
	for node in nodes:
		if node.node_type == type:
			count += 1
	return count


func test_difficulty_0_does_not_add_hard_combat():
	var gen := _make_generator()
	var nodes := gen.generate(1, 0)
	var hard_count := _count_nodes_by_type(nodes, GameEnums.MapNodeType.HARD_COMBAT)
	# Default random pool has 4 hard combat nodes
	assert_int(hard_count).is_equal(4)


func test_difficulty_1_adds_one_hard_combat_in_chapter_1():
	var gen := _make_generator()
	var nodes := gen.generate(1, 1)
	var hard_count := _count_nodes_by_type(nodes, GameEnums.MapNodeType.HARD_COMBAT)
	assert_int(hard_count).is_equal(5)


func test_difficulty_1_adds_one_hard_combat_in_chapter_2():
	var gen := _make_generator()
	var nodes := gen.generate(2, 1)
	var hard_count := _count_nodes_by_type(nodes, GameEnums.MapNodeType.HARD_COMBAT)
	assert_int(hard_count).is_equal(5)


func test_difficulty_1_does_not_add_hard_combat_in_chapter_3():
	var gen := _make_generator()
	var nodes := gen.generate(3, 1)
	var hard_count := _count_nodes_by_type(nodes, GameEnums.MapNodeType.HARD_COMBAT)
	assert_int(hard_count).is_equal(4)


func test_difficulty_1_reduces_road_count_by_one():
	var gen_no_diff := _make_generator(123)
	var nodes_no_diff := gen_no_diff.generate(1, 0)
	var road_count_no_diff := _count_nodes_by_type(nodes_no_diff, GameEnums.MapNodeType.ROAD)

	var gen_diff := _make_generator(123)
	var nodes_diff := gen_diff.generate(1, 1)
	var road_count_diff := _count_nodes_by_type(nodes_diff, GameEnums.MapNodeType.ROAD)

	assert_int(road_count_diff).is_equal(road_count_no_diff - 1)


func test_difficulty_2_also_adds_hard_combat():
	var gen := _make_generator()
	var nodes := gen.generate(1, 2)
	var hard_count := _count_nodes_by_type(nodes, GameEnums.MapNodeType.HARD_COMBAT)
	assert_int(hard_count).is_equal(5)

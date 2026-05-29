class_name NodeManager
extends RefCounted

signal player_moved(to_node_id: StringName, stamina_cost: int)
signal node_visited(node_id: StringName, node_type: GameEnums.MapNodeType)
signal node_cleared(node_id: StringName)

var _map_state: MapState
var _path_finder: PathFinder
var _stamina: Stamina
var _movement_cost_modifier: int = 0


func initialize(map_state: MapState, path_finder: PathFinder, stamina: Stamina) -> void:
	_map_state = map_state
	_path_finder = path_finder
	_stamina = stamina


func set_movement_cost_modifier(modifier: int) -> void:
	_movement_cost_modifier = modifier


func get_movement_cost() -> int:
	return maxi(1 + _movement_cost_modifier, 0)


func can_move_to(target_node_id: StringName) -> bool:
	var target := _map_state.get_node_by_id(target_node_id)
	if target == null:
		return false

	var player_node := _map_state.get_player_node()
	if player_node == null:
		return false

	if not _path_finder.is_adjacent(player_node.id, target_node_id):
		return false

	var cost := get_movement_cost()
	return _stamina.current_stamina >= cost


func move_to(target_node_id: StringName) -> bool:
	if not can_move_to(target_node_id):
		return false

	var cost := get_movement_cost()
	_stamina.deduct(cost)
	_map_state.visit_node(target_node_id)

	var target := _map_state.get_node_by_id(target_node_id)
	player_moved.emit(target_node_id, cost)
	node_visited.emit(target_node_id, target.node_type)

	return true


func get_current_node() -> MapNodeData:
	return _map_state.get_player_node()


func get_adjacent_nodes() -> Array[MapNodeData]:
	var player_node := _map_state.get_player_node()
	if player_node == null:
		return []
	return _map_state.get_neighbors(player_node.id)


func clear_current_node() -> void:
	var player_node := _map_state.get_player_node()
	if player_node == null:
		return
	_map_state.clear_node(player_node.id)
	node_cleared.emit(player_node.id)

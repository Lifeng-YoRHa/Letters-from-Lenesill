class_name MapRenderer
extends Control

signal node_selected(node_id: StringName)

@onready var _map_container: Control = $MapContainer
@onready var _stamina_label: Label = $HUD/StaminaLabel
@onready var _gold_label: Label = $HUD/GoldLabel
@onready var _chapter_label: Label = $HUD/ChapterLabel

var _map_state: MapState
var _node_buttons: Dictionary = {}
var _player_marker: Control
var _connection_lines: Array[Line2D] = []

func initialize(map_state: MapState) -> void:
	_map_state = map_state
	_render_map()


func _render_map() -> void:
	for child in _map_container.get_children():
		child.queue_free()
	_node_buttons.clear()
	for old_line in _connection_lines:
		old_line.queue_free()
	_connection_lines.clear()

	_create_node_buttons()
	_create_player_marker()
	_update_connections()
	update_player_marker()


func _update_connections() -> void:
	for old_line in _connection_lines:
		old_line.queue_free()
	_connection_lines.clear()

	var player_node := _map_state.get_player_node()
	var player_id := player_node.id if player_node != null else &""

	for node: MapNodeData in _map_state.nodes.values():
		for conn_id in node.connections:
			if not (node.id < conn_id):
				continue

			var neighbor := _map_state.get_node_by_id(conn_id)
			if neighbor == null:
				continue

			var node_visible := node.visibility != GameEnums.MapNodeVisibility.UNEXPLORED
			var neighbor_visible := neighbor.visibility != GameEnums.MapNodeVisibility.UNEXPLORED
			if not node_visible or not neighbor_visible:
				continue

			var node_visited := node.visibility == GameEnums.MapNodeVisibility.VISITED or node.visibility == GameEnums.MapNodeVisibility.CLEARED
			var neighbor_visited := neighbor.visibility == GameEnums.MapNodeVisibility.VISITED or neighbor.visibility == GameEnums.MapNodeVisibility.CLEARED
			var both_visited := node_visited and neighbor_visited
			var is_player_connection := node.id == player_id or conn_id == player_id

			if not both_visited and not is_player_connection:
				continue

			var line := Line2D.new()
			line.default_color = Color(0.5, 0.5, 0.55, 0.35)
			line.width = 1.5
			line.antialiased = true

			var p0 := node.position + Vector2(20, 20)
			var p2 := neighbor.position + Vector2(20, 20)
			var points := _bezier_points(p0, p2, node.layer, neighbor.layer, node.id < conn_id)
			for pt in points:
				line.add_point(pt)

			_map_container.add_child(line)
			_connection_lines.append(line)


func _bezier_points(p0: Vector2, p2: Vector2, layer_a: int, layer_b: int, flip: bool) -> Array[Vector2]:
	var mid := (p0 + p2) * 0.5
	var diff := p2 - p0
	var layer_diff := absi(layer_a - layer_b)
	var offset := float(layer_diff) * 20.0 + 10.0

	var perp := Vector2(-diff.y, diff.x).normalized()
	if perp == Vector2.ZERO:
		perp = Vector2(0, 1)
	if flip:
		perp = -perp

	var p1 := mid + perp * offset

	var points: Array[Vector2] = []
	var segments := 16
	for i in range(segments + 1):
		var t := float(i) / segments
		var omt := 1.0 - t
		var pt := p0 * omt * omt + p1 * 2.0 * omt * t + p2 * t * t
		points.append(pt)
	return points


func refresh_connections() -> void:
	_update_connections()


func _create_node_buttons() -> void:
	for node: MapNodeData in _map_state.nodes.values():
		var btn := Button.new()
		btn.position = node.position
		btn.custom_minimum_size = Vector2(40, 40)
		btn.size = Vector2(40, 40)
		btn.text = _node_type_label(node.node_type)
		btn.disabled = node.visibility == GameEnums.MapNodeVisibility.UNEXPLORED
		btn.modulate = _node_color(node.visibility)
		btn.pressed.connect(func() -> void: _on_node_pressed(node.id))
		_map_container.add_child(btn)
		_node_buttons[node.id] = btn


func _create_player_marker() -> void:
	_player_marker = Control.new()
	_player_marker.custom_minimum_size = Vector2(16, 16)
	_player_marker.size = Vector2(16, 16)

	var dot := ColorRect.new()
	dot.color = Color(0.2, 0.8, 1, 1)
	dot.custom_minimum_size = Vector2(16, 16)
	dot.size = Vector2(16, 16)
	_player_marker.add_child(dot)
	_map_container.add_child(_player_marker)


func update_player_marker() -> void:
	var player_node := _map_state.get_player_node()
	if player_node != null and _player_marker != null:
		_player_marker.position = player_node.position + Vector2(12, 12)


func _on_node_pressed(node_id: StringName) -> void:
	node_selected.emit(node_id)


func update_hud(stamina: int, max_stamina: int, gold: int, chapter: int) -> void:
	_stamina_label.text = "Stamina: %d / %d" % [stamina, max_stamina]
	_gold_label.text = "Gold: %d" % gold
	_chapter_label.text = "Chapter: %d" % chapter


func refresh_node(node_id: StringName) -> void:
	var node := _map_state.get_node_by_id(node_id)
	var btn := _node_buttons.get(node_id) as Button
	if btn != null and node != null:
		btn.modulate = _node_color(node.visibility)
		btn.disabled = node.visibility == GameEnums.MapNodeVisibility.UNEXPLORED
		btn.text = _node_type_label(node.node_type)


func _node_type_label(type: GameEnums.MapNodeType) -> String:
	match type:
		GameEnums.MapNodeType.START:
			return "S"
		GameEnums.MapNodeType.ROAD:
			return "·"
		GameEnums.MapNodeType.NORMAL_COMBAT:
			return "!"
		GameEnums.MapNodeType.HARD_COMBAT:
			return "!!"
		GameEnums.MapNodeType.BOSS:
			return "B"
		GameEnums.MapNodeType.RANDOM_EVENT:
			return "?"
		GameEnums.MapNodeType.RUINS:
			return "R"
		GameEnums.MapNodeType.BLACK_MARKET:
			return "$"
		GameEnums.MapNodeType.SAFE_HOUSE:
			return "H"
		GameEnums.MapNodeType.QUEST:
			return "Q"
	return "?"


func _node_color(visibility: GameEnums.MapNodeVisibility) -> Color:
	match visibility:
		GameEnums.MapNodeVisibility.UNEXPLORED:
			return Color.TRANSPARENT
		GameEnums.MapNodeVisibility.REVEALED:
			return Color(0.65, 0.65, 0.75, 0.9)
		GameEnums.MapNodeVisibility.VISITED:
			return Color.WHITE
		GameEnums.MapNodeVisibility.CLEARED:
			return Color(0.5, 0.9, 0.5, 1)
	return Color.WHITE

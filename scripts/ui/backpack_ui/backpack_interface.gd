class_name BackpackInterface
extends Control

signal closed

const CELL_SIZE := 40

const ITEM_COLORS := {
	GameEnums.ItemType.WEAPON: Color(0.75, 0.35, 0.35),
	GameEnums.ItemType.CONSUMABLE: Color(0.35, 0.7, 0.4),
	GameEnums.ItemType.RELIC: Color(0.9, 0.75, 0.25),
	GameEnums.ItemType.BACKPACK: Color(0.35, 0.55, 0.8),
}

@onready var _primary_grid_container: Control = %PrimaryGridContainer
@onready var _secondary_container: HBoxContainer = %SecondaryContainer
@onready var _weapon_label: Label = %WeaponLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _pocket_a_container: Control = %PocketAContainer
@onready var _pocket_b_container: Control = %PocketBContainer

var _backpack_manager: BackpackManager


func initialize(backpack_manager: BackpackManager) -> void:
	if _backpack_manager != null:
		_disconnect_signals()

	_backpack_manager = backpack_manager
	_connect_signals()
	_refresh()


func _connect_signals() -> void:
	if _backpack_manager == null:
		return
	_backpack_manager.item_added.connect(_on_items_changed)
	_backpack_manager.item_removed.connect(_on_items_changed)
	_backpack_manager.weapon_equipped.connect(_on_weapon_changed)
	_backpack_manager.weapon_unequipped.connect(_on_weapon_changed)
	_backpack_manager.gold_changed.connect(_on_gold_changed)


func _disconnect_signals() -> void:
	if _backpack_manager == null:
		return
	_backpack_manager.item_added.disconnect(_on_items_changed)
	_backpack_manager.item_removed.disconnect(_on_items_changed)
	_backpack_manager.weapon_equipped.disconnect(_on_weapon_changed)
	_backpack_manager.weapon_unequipped.disconnect(_on_weapon_changed)
	_backpack_manager.gold_changed.disconnect(_on_gold_changed)


func _on_items_changed(_item: ItemData) -> void:
	_refresh_grids()


func _on_weapon_changed(_weapon: ItemData) -> void:
	_update_weapon()


func _on_gold_changed(_amount: int) -> void:
	_update_gold()


func _refresh() -> void:
	_refresh_grids()
	_update_weapon()
	_update_gold()


func _refresh_grids() -> void:
	if _backpack_manager == null:
		return

	_render_grid(_primary_grid_container, _backpack_manager.primary_grid)

	for child in _secondary_container.get_children():
		child.queue_free()

	for grid in _backpack_manager.secondary_grids:
		var container := Control.new()
		_secondary_container.add_child(container)
		_render_grid(container, grid)

	_render_grid(_pocket_a_container, _backpack_manager.pocket_a)
	_render_grid(_pocket_b_container, _backpack_manager.pocket_b)


func _render_grid(container: Control, grid: BackpackGrid) -> void:
	for child in container.get_children():
		child.queue_free()

	var dims := grid.get_grid_dimensions()
	container.custom_minimum_size = Vector2(dims.x * CELL_SIZE, dims.y * CELL_SIZE)

	var drawer := _GridDrawer.new(dims.x, dims.y, CELL_SIZE)
	container.add_child(drawer)

	for item in grid.get_items():
		var pos := grid.get_item_position(item)
		if pos.is_empty():
			continue

		var item_dims := item.get_dimensions(pos.rotated)
		var panel := Panel.new()
		panel.position = Vector2(pos.x * CELL_SIZE, pos.y * CELL_SIZE)
		panel.size = Vector2(item_dims.x * CELL_SIZE, item_dims.y * CELL_SIZE)
		panel.mouse_filter = Control.MOUSE_FILTER_STOP

		var color: Color = ITEM_COLORS.get(item.item_type, Color(0.5, 0.5, 0.5))
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.border_color = Color(color.r * 0.7, color.g * 0.7, color.b * 0.7)
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		panel.add_theme_stylebox_override("panel", style)

		var label := Label.new()
		label.text = _abbreviate(item.display_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
		label.custom_minimum_size = panel.size
		label.size = panel.size
		label.add_theme_font_size_override("font_size", 11)
		panel.add_child(label)

		panel.tooltip_text = "%s\n%s" % [item.display_name, item.description]
		container.add_child(panel)


func _update_weapon() -> void:
	if _backpack_manager == null:
		return
	if _backpack_manager.equipped_weapon != null:
		_weapon_label.text = "Weapon: %s" % _backpack_manager.equipped_weapon.display_name
	else:
		_weapon_label.text = "Weapon: None"


func _update_gold() -> void:
	if _backpack_manager == null:
		return
	_gold_label.text = "Gold: %d" % _backpack_manager.gold_count


func _abbreviate(name: String) -> String:
	if name.length() <= 8:
		return name
	return name.substr(0, 7) + "…"


class _GridDrawer:
	extends Control

	var _grid_w: int
	var _grid_h: int
	var _cell_size: int

	func _init(grid_w: int, grid_h: int, cell_size: int) -> void:
		_grid_w = grid_w
		_grid_h = grid_h
		_cell_size = cell_size
		custom_minimum_size = Vector2(grid_w * cell_size, grid_h * cell_size)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var color := Color(0.3, 0.3, 0.35, 0.5)
		for x in range(_grid_w + 1):
			var x_pos := x * _cell_size
			draw_line(Vector2(x_pos, 0), Vector2(x_pos, _grid_h * _cell_size), color, 1.0)
		for y in range(_grid_h + 1):
			var y_pos := y * _cell_size
			draw_line(Vector2(0, y_pos), Vector2(_grid_w * _cell_size, y_pos), color, 1.0)

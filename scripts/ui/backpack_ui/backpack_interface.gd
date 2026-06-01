class_name BackpackInterface
extends Control

signal closed
signal item_use_requested(item: ItemData, grid: BackpackGrid)

const CELL_SIZE := 40

const ITEM_COLORS := {
	GameEnums.ItemType.WEAPON: Color(0.75, 0.35, 0.35),
	GameEnums.ItemType.CONSUMABLE: Color(0.35, 0.7, 0.4),
	GameEnums.ItemType.RELIC: Color(0.9, 0.75, 0.25),
	GameEnums.ItemType.BACKPACK: Color(0.35, 0.55, 0.8),
	GameEnums.ItemType.GOLD: Color(0.9, 0.8, 0.2),
}

@onready var _primary_grid_container: Control = %PrimaryGridContainer
@onready var _secondary_container: HBoxContainer = %SecondaryContainer
@onready var _weapon_label: Label = %WeaponLabel
@onready var _gold_label: Label = %GoldLabel
@onready var _pocket_a_container: Control = %PocketAContainer
@onready var _pocket_b_container: Control = %PocketBContainer

@onready var _context_menu: PanelContainer = %ContextMenu
@onready var _use_button: Button = %UseButton
@onready var _rotate_button: Button = %RotateButton
@onready var _detail_button: Button = %DetailButton

@onready var _detail_panel: PanelContainer = %DetailPanel
@onready var _detail_name: Label = %NameLabel
@onready var _detail_type: Label = %TypeLabel
@onready var _detail_size: Label = %SizeLabel
@onready var _detail_desc: Label = %DescLabel
@onready var _detail_effect: Label = %EffectLabel
@onready var _detail_close: Button = %CloseButton

var _backpack_manager: BackpackManager
var _context_item: ItemData = null
var _context_grid: BackpackGrid = null


func _ready() -> void:
	_use_button.pressed.connect(_on_use_pressed)
	_rotate_button.pressed.connect(_on_rotate_pressed)
	_detail_button.pressed.connect(_on_detail_pressed)
	_detail_close.pressed.connect(_on_detail_close_pressed)


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
		if item.item_type == GameEnums.ItemType.GOLD:
			label.text = "%d" % _backpack_manager.gold_count
		else:
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
		panel.set_meta("drag_started", false)
		panel.gui_input.connect(func(event: InputEvent) -> void:
			_on_item_panel_input(event, panel, item, grid)
		)
		panel.set_drag_forwarding(
			_on_item_get_drag_data_with_panel.bind(item, grid, panel),
			Callable(),
			Callable()
		)
		container.add_child(panel)

	container.set_drag_forwarding(
		Callable(),
		_on_grid_can_drop_data.bind(grid),
		_on_grid_drop_data.bind(grid)
	)


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


func _on_item_get_drag_data(_at_position: Vector2, item: ItemData, grid: BackpackGrid) -> Variant:
	var drag_data := {"item": item, "source_grid": grid}
	var dims := item.get_dimensions(false)
	var preview := Panel.new()
	preview.size = Vector2(dims.x * CELL_SIZE, dims.y * CELL_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.4)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	preview.add_theme_stylebox_override("panel", style)
	set_drag_preview(preview)
	return drag_data


func _on_item_get_drag_data_with_panel(_at_position: Vector2, item: ItemData, grid: BackpackGrid, panel: Control) -> Variant:
	panel.set_meta("drag_started", true)
	return _on_item_get_drag_data(_at_position, item, grid)


func _on_item_panel_input(event: InputEvent, panel: Control, item: ItemData, grid: BackpackGrid) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		panel.set_meta("drag_started", false)
	else:
		if not panel.get_meta("drag_started", false):
			_show_context_menu(item, grid, panel.get_global_mouse_position())


func _show_context_menu(item: ItemData, grid: BackpackGrid, pos: Vector2) -> void:
	_context_item = item
	_context_grid = grid
	_context_menu.position = Vector2i(int(pos.x), int(pos.y))
	_context_menu.visible = true


func _hide_context_menu() -> void:
	_context_menu.visible = false
	_context_item = null
	_context_grid = null


func _on_use_pressed() -> void:
	if _context_item == null or _context_grid == null:
		return
	item_use_requested.emit(_context_item, _context_grid)
	_hide_context_menu()


func _on_rotate_pressed() -> void:
	if _context_item == null or _context_grid == null:
		return
	if _context_grid.rotate_item(_context_item):
		_refresh_grids()
		_hide_context_menu()
		return

	# 旋转失败：进入强制拖拽（旋转后的方向）
	var old_pos := _context_grid.get_item_position(_context_item)
	if old_pos.is_empty():
		_hide_context_menu()
		return
	var new_rotated: bool = not old_pos.rotated
	var drag_data := {
		"item": _context_item,
		"source_grid": _context_grid,
		"forced_rotated": new_rotated,
		"fallback_pos": old_pos,
	}
	var dims := _context_item.get_dimensions(new_rotated)
	var preview := Panel.new()
	preview.size = Vector2(dims.x * CELL_SIZE, dims.y * CELL_SIZE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.4)
	preview.add_theme_stylebox_override("panel", style)
	_hide_context_menu()
	call_deferred("_start_forced_drag", drag_data, preview)


func _start_forced_drag(data: Variant, preview: Control) -> void:
	force_drag(data, preview)


func _on_detail_pressed() -> void:
	if _context_item == null:
		return
	_show_detail_panel(_context_item)
	_hide_context_menu()


func _show_detail_panel(item: ItemData) -> void:
	_detail_name.text = item.display_name
	_detail_type.text = "Type: %s" % GameEnums.ItemType.keys()[item.item_type]
	_detail_size.text = "Size: %d×%d" % [item.width, item.height]
	_detail_desc.text = item.description if item.description != "" else "No description."
	_detail_effect.text = _get_item_effect_text(item)
	_detail_panel.visible = true


func _hide_detail_panel() -> void:
	_detail_panel.visible = false


func _get_item_effect_text(item: ItemData) -> String:
	match item.id:
		&"energy_drink": return "恢复 7 点体力（可通过幸存者笔记提升）"
		&"stone": return "消耗 2 点体力，逃离当前战斗"
		&"torch": return "消耗 2 点体力，对敌人造成 30 点伤害"
		&"whetstone": return "恢复 3 点武器耐久（可通过幸存者笔记提升）"
		&"flashlight": return "揭示 2 个随机隐藏节点的类型（可通过幸存者笔记提升）"
		&"safe_house_key": return "打开安全屋"
		_: return "效果未知"


func _on_detail_close_pressed() -> void:
	_hide_detail_panel()


func _on_grid_can_drop_data(at_position: Vector2, data: Variant, grid: BackpackGrid) -> bool:
	if not data is Dictionary:
		return false
	var item: ItemData = data.get("item")
	if item == null:
		return false
	var source_grid: BackpackGrid = data.get("source_grid")

	var rotated: bool
	if data.has("forced_rotated"):
		rotated = data.forced_rotated
	else:
		var old_pos := source_grid.get_item_position(item)
		rotated = old_pos.get("rotated", false) if not old_pos.is_empty() else false

	var grid_pos := Vector2i(int(at_position.x / CELL_SIZE), int(at_position.y / CELL_SIZE))
	if source_grid == grid:
		return grid.can_fit_excluding(item, grid_pos.x, grid_pos.y, item, rotated)
	return grid.can_fit(item, grid_pos.x, grid_pos.y, rotated)


func _on_grid_drop_data(at_position: Vector2, data: Variant, grid: BackpackGrid) -> void:
	if not data is Dictionary:
		return
	var item: ItemData = data.get("item")
	var source_grid: BackpackGrid = data.get("source_grid")
	if item == null or source_grid == null:
		return

	var grid_pos := Vector2i(int(at_position.x / CELL_SIZE), int(at_position.y / CELL_SIZE))

	var rotated: bool
	var fallback_pos: Dictionary = {}
	if data.has("forced_rotated"):
		rotated = data.forced_rotated
		fallback_pos = data.get("fallback_pos", {})
	else:
		var old_pos := source_grid.get_item_position(item)
		rotated = old_pos.get("rotated", false) if not old_pos.is_empty() else false
		fallback_pos = old_pos

	var removed := source_grid.remove(item)
	if not removed:
		return

	if not grid.place(item, grid_pos.x, grid_pos.y, rotated):
		if not fallback_pos.is_empty():
			source_grid.place(item, fallback_pos.x, fallback_pos.y, fallback_pos.rotated)
		return

	_refresh_grids()


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

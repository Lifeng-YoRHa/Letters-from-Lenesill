class_name ShopInterface
extends Control

signal closed

var _shop_manager: ShopManager
var _backpack_manager: BackpackManager
var _selected_shop_slot: int = -1
var _selected_inventory_item: ItemData = null

@onready var _stock_grid: VBoxContainer = %StockGrid
@onready var _shop_detail_panel: Panel = %ShopDetailPanel
@onready var _shop_detail_name: Label = %ShopDetailName
@onready var _shop_detail_desc: Label = %ShopDetailDesc
@onready var _shop_detail_price: Label = %ShopDetailPrice
@onready var _buy_button: Button = %BuyButton
@onready var _inventory_list: VBoxContainer = %InventoryList
@onready var _sell_detail_panel: Panel = %SellDetailPanel
@onready var _sell_detail_name: Label = %SellDetailName
@onready var _sell_detail_desc: Label = %SellDetailDesc
@onready var _sell_detail_price: Label = %SellDetailPrice
@onready var _sell_button: Button = %SellButton
@onready var _gold_label: Label = %GoldLabel


func _ready() -> void:
	_buy_button.pressed.connect(_on_buy_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)


func initialize(shop_manager: ShopManager, backpack_manager: BackpackManager) -> void:
	_shop_manager = shop_manager
	_backpack_manager = backpack_manager

	if not _shop_manager.item_purchased.is_connected(_on_item_purchased):
		_shop_manager.item_purchased.connect(_on_item_purchased)
	if not _shop_manager.item_sold.is_connected(_on_item_sold):
		_shop_manager.item_sold.connect(_on_item_sold)
	if not _shop_manager.stock_depleted.is_connected(_on_stock_depleted):
		_shop_manager.stock_depleted.connect(_on_stock_depleted)
	if not _backpack_manager.gold_changed.is_connected(_on_gold_changed):
		_backpack_manager.gold_changed.connect(_on_gold_changed)
	if not _backpack_manager.item_added.is_connected(_on_inventory_changed):
		_backpack_manager.item_added.connect(_on_inventory_changed)
	if not _backpack_manager.item_removed.is_connected(_on_inventory_changed):
		_backpack_manager.item_removed.connect(_on_inventory_changed)

	_refresh_all()


func _refresh_all() -> void:
	_update_gold()
	_render_shop_slots()
	_render_inventory_list()
	_clear_selection()


func _update_gold() -> void:
	_gold_label.text = "💰 %d" % _backpack_manager.gold_count


# ---------- 商店槽位渲染 ----------
func _render_shop_slots() -> void:
	for child in _stock_grid.get_children():
		child.queue_free()

	for i in range(_shop_manager.slots.size()):
		var slot: ShopManager.ShopSlot = _shop_manager.slots[i]
		var btn := _create_shop_slot_button(i, slot)
		_stock_grid.add_child(btn)


func _create_shop_slot_button(index: int, slot: ShopManager.ShopSlot) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(260, 60)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT

	if slot.quantity <= 0:
		btn.disabled = true
		btn.text = "售罄"
		btn.tooltip_text = "该商品已售完"
	else:
		var price := _shop_manager.get_final_buy_price(index)
		btn.text = "%s  ×%d  %d G" % [slot.item.display_name, slot.quantity, price]
		var can_buy := _shop_manager.can_purchase(index)
		btn.disabled = not can_buy
		if not can_buy:
			if _backpack_manager.gold_count < price:
				btn.tooltip_text = "金币不足"
			else:
				btn.tooltip_text = "背包空间不足"
		_apply_item_color(btn, slot.item.item_type)
		btn.pressed.connect(_on_shop_slot_clicked.bind(index))

	return btn


func _on_shop_slot_clicked(index: int) -> void:
	_selected_shop_slot = index
	_selected_inventory_item = null
	_show_shop_detail(index)
	_hide_sell_detail()


func _show_shop_detail(index: int) -> void:
	var slot: ShopManager.ShopSlot = _shop_manager.slots[index]
	_shop_detail_name.text = slot.item.display_name
	_shop_detail_desc.text = slot.item.description if slot.item.description != "" else ""
	var price := _shop_manager.get_final_buy_price(index)
	_shop_detail_price.text = "价格: %d G" % price
	_buy_button.disabled = not _shop_manager.can_purchase(index)
	_shop_detail_panel.visible = true


func _on_buy_pressed() -> void:
	if _selected_shop_slot >= 0:
		_shop_manager.purchase(_selected_shop_slot)


# ---------- 背包列表渲染 ----------
func _render_inventory_list() -> void:
	for child in _inventory_list.get_children():
		child.queue_free()

	var items := _get_inventory_items()
	for item in items:
		var btn := _create_inventory_button(item)
		_inventory_list.add_child(btn)

	# ScrollContainer 在首次从不可见变为可见时，需要延迟一帧才能正确计算滚动区域
	call_deferred("_update_inventory_list_minimum_size")


func _update_inventory_list_minimum_size() -> void:
	_inventory_list.custom_minimum_size = Vector2(0, _inventory_list.get_combined_minimum_size().y)


func _get_inventory_items() -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in _backpack_manager.get_total_items():
		if item.item_type != GameEnums.ItemType.BACKPACK:
			result.append(item)
	if _backpack_manager.equipped_weapon != null:
		result.append(_backpack_manager.equipped_weapon)
	return result


func _create_inventory_button(item: ItemData) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(240, 40)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var sell_price := _shop_manager.get_sell_price(item)
	btn.text = "%s  %d G" % [item.display_name, sell_price]
	_apply_item_color(btn, item.item_type)
	btn.pressed.connect(_on_inventory_item_clicked.bind(item))
	return btn


func _on_inventory_item_clicked(item: ItemData) -> void:
	_selected_inventory_item = item
	_selected_shop_slot = -1
	_show_sell_detail(item)
	_hide_shop_detail()


func _show_sell_detail(item: ItemData) -> void:
	_sell_detail_name.text = item.display_name
	_sell_detail_desc.text = item.description if item.description != "" else ""
	var price := _shop_manager.get_sell_price(item)
	_sell_detail_price.text = "出售价格: %d G" % price
	_sell_button.disabled = not _shop_manager.can_sell(item)
	_sell_detail_panel.visible = true


func _on_sell_pressed() -> void:
	if _selected_inventory_item != null:
		_shop_manager.sell(_selected_inventory_item)


# ---------- 信号回调 ----------
func _on_item_purchased(_item: ItemData, _price: int) -> void:
	_refresh_all()


func _on_item_sold(_item: ItemData, _price: int) -> void:
	_refresh_all()


func _on_stock_depleted(_index: int) -> void:
	_refresh_all()


func _on_gold_changed(_new_amount: int) -> void:
	_update_gold()
	_render_shop_slots()
	if _selected_shop_slot >= 0:
		_show_shop_detail(_selected_shop_slot)


func _on_inventory_changed(_item: ItemData) -> void:
	_render_inventory_list()
	if _selected_inventory_item != null:
		var still_has := false
		for item in _backpack_manager.get_total_items():
			if item == _selected_inventory_item:
				still_has = true
				break
		if _backpack_manager.equipped_weapon == _selected_inventory_item:
			still_has = true
		if not still_has:
			_hide_sell_detail()


# ---------- 辅助 ----------
func _clear_selection() -> void:
	_selected_shop_slot = -1
	_selected_inventory_item = null
	_hide_shop_detail()
	_hide_sell_detail()


func _hide_shop_detail() -> void:
	_shop_detail_panel.visible = false


func _hide_sell_detail() -> void:
	_sell_detail_panel.visible = false


func _apply_item_color(btn: Button, item_type: GameEnums.ItemType) -> void:
	match item_type:
		GameEnums.ItemType.WEAPON:
			btn.modulate = Color(0.9, 0.5, 0.4)
		GameEnums.ItemType.CONSUMABLE:
			btn.modulate = Color(0.5, 0.8, 0.5)
		GameEnums.ItemType.RELIC:
			btn.modulate = Color(0.9, 0.8, 0.4)
		GameEnums.ItemType.BACKPACK:
			btn.modulate = Color(0.5, 0.6, 0.9)


func _on_close_pressed() -> void:
	closed.emit()

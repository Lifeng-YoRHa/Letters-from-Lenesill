class_name GameScene
extends Node

@onready var _game_manager: GameManager = $GameManager
@onready var _ui_manager: UIManager = $UIManager

const _CONFIRM_EXIT_MESSAGE: String = "The un-stored progress will be lost. Return to main menu anyway?"
var _fade_tween: Tween
var _exit_confirm_dialog: ConfirmationDialog = null

func _ready() -> void:
	_ui_manager.initialize(_game_manager)
	_game_manager.state_changed.connect(_on_state_changed)
	_game_manager.combat_prepared.connect(_on_combat_prepared)
	_game_manager.chapter_started.connect(_on_chapter_started)
	_game_manager.adventure_started.connect(_on_adventure_started)
	_game_manager.loot_generated.connect(_on_loot_generated)
	_game_manager.player_died.connect(_on_player_died)
	_connect_menu_signals()
	_connect_overlay_signals()
	_connect_save_slot_signals()
	_ui_manager.show_screen("MainMenu")


func _connect_menu_signals() -> void:
	var main_menu: MainMenu = _ui_manager.get_screen("MainMenu")
	if main_menu != null:
		main_menu.new_adventure_pressed.connect(_on_new_adventure_pressed)
		main_menu.continue_pressed.connect(_on_continue_pressed)
		main_menu.survivor_notes_pressed.connect(_on_survivor_notes_pressed)
		main_menu.settings_pressed.connect(_on_settings_pressed)
		main_menu.exit_game_pressed.connect(_on_exit_game_pressed)
	_refresh_main_menu_resume()


func _refresh_main_menu_resume() -> void:
	var main_menu: MainMenu = _ui_manager.get_screen("MainMenu")
	if main_menu == null:
		return
	var has_any_save := false
	for i in range(SaveLoadManager.SAVE_SLOT_COUNT):
		if _game_manager.save_load_manager.has_save(i):
			has_any_save = true
			break
	main_menu.set_resume_available(has_any_save)


func _on_new_adventure_pressed() -> void:
	_game_manager.start_new_adventure()


func _on_continue_pressed() -> void:
	var save_slot_screen := _ui_manager.get_screen("SaveSlotScreen") as SaveSlotScreen
	if save_slot_screen != null:
		save_slot_screen.initialize(_game_manager.save_load_manager)
	_ui_manager.show_screen("SaveSlotScreen")


func _on_survivor_notes_pressed() -> void:
	# TODO: show survivor notes screen
	pass


func _on_settings_pressed() -> void:
	# TODO: show settings panel
	pass


func _on_exit_game_pressed() -> void:
	get_tree().quit()


func _on_pause_save_pressed() -> void:
	var save_slot_screen := _ui_manager.get_screen("SaveSlotScreen") as SaveSlotScreen
	if save_slot_screen != null:
		save_slot_screen.initialize(_game_manager.save_load_manager, SaveSlotScreen.Mode.SAVE)
	_ui_manager.show_screen("SaveSlotScreen")


func _connect_save_slot_signals() -> void:
	var save_slot_screen := _ui_manager.get_screen("SaveSlotScreen") as SaveSlotScreen
	if save_slot_screen != null:
		save_slot_screen.slot_selected.connect(_on_save_slot_selected)
		save_slot_screen.slot_continue_requested.connect(_on_slot_continue_requested)
		save_slot_screen.slot_delete_requested.connect(_on_slot_delete_requested)
		save_slot_screen.back_pressed.connect(_on_save_slot_back)


func _on_save_slot_selected(slot_index: int) -> void:
	var save_slot_screen := _ui_manager.get_screen("SaveSlotScreen") as SaveSlotScreen
	if save_slot_screen != null and save_slot_screen.mode == SaveSlotScreen.Mode.SAVE:
		var saved := _game_manager.save_adventure(slot_index)
		if saved:
			_ui_manager.show_screen("MapView")
			_ui_manager.show_overlay("PauseMenu")
		else:
			push_warning("Failed to save adventure to slot %d" % slot_index)


func _on_slot_continue_requested(slot_index: int) -> void:
	var loaded := _game_manager.load_adventure(slot_index)
	if not loaded:
		push_warning("Failed to load adventure from slot %d" % slot_index)
		# TODO: show error dialog to player


func _on_slot_delete_requested(slot_index: int) -> void:
	_game_manager.save_load_manager.delete_slot(slot_index)
	var save_slot_screen := _ui_manager.get_screen("SaveSlotScreen") as SaveSlotScreen
	if save_slot_screen != null:
		save_slot_screen.initialize(_game_manager.save_load_manager)
	var has_any_save := false
	for i in range(SaveLoadManager.SAVE_SLOT_COUNT):
		if _game_manager.save_load_manager.has_save(i):
			has_any_save = true
			break
	if not has_any_save:
		_ui_manager.show_screen("MainMenu")
		_refresh_main_menu_resume()


func _on_save_slot_back() -> void:
	var save_slot_screen := _ui_manager.get_screen("SaveSlotScreen") as SaveSlotScreen
	if save_slot_screen != null and save_slot_screen.mode == SaveSlotScreen.Mode.SAVE:
		_ui_manager.show_screen("MapView")
		_ui_manager.show_overlay("PauseMenu")
	else:
		_ui_manager.show_screen("MainMenu")


func _connect_overlay_signals() -> void:
	var shop := _ui_manager.get_overlay("ShopOverlay") as ShopInterface
	if shop != null:
		shop.closed.connect(_on_overlay_closed)

	var event := _ui_manager.get_overlay("EventOverlay") as EventInterface
	if event != null:
		event.closed.connect(_on_overlay_closed)

	var safe_house := _ui_manager.get_overlay("SafeHouse") as SafeHouseInterface
	if safe_house != null:
		safe_house.closed.connect(_on_overlay_closed)
		safe_house.rest_requested.connect(_on_safe_house_rest)
		safe_house.item_taken.connect(_on_safe_house_item_taken)
		safe_house.gold_taken.connect(_on_safe_house_gold_taken)
		safe_house.weapon_repaired.connect(_on_safe_house_weapon_repaired)

	var pause := _ui_manager.get_overlay("PauseMenu") as PauseMenu
	if pause != null:
		pause.resume_pressed.connect(_on_pause_resume_pressed)
		pause.save_pressed.connect(_on_pause_save_pressed)
		pause.return_to_main_menu_pressed.connect(_on_return_to_main_menu)

	var chapter := _ui_manager.get_overlay("ChapterTransition") as ChapterTransition
	if chapter != null:
		chapter.dismissed.connect(_on_overlay_closed)

	var ending := _ui_manager.get_overlay("EndingScreen") as EndingScreen
	if ending != null:
		ending.return_to_main_menu_pressed.connect(_on_return_to_main_menu)

	var backpack := _ui_manager.get_overlay("BackpackUI") as BackpackInterface
	if backpack != null:
		backpack.closed.connect(_on_overlay_closed)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B:
				if _game_manager.current_state == GameManager.GameState.MAP_EXPLORATION:
					if _ui_manager.is_overlay_open("BackpackUI"):
						_ui_manager.hide_overlay("BackpackUI")
					else:
						_ui_manager.show_overlay("BackpackUI")
			KEY_P:
				if not _ui_manager.is_overlay_open("PauseMenu"):
					if _game_manager.current_state not in [
						GameManager.GameState.MAIN_MENU,
						GameManager.GameState.ENDING,
					]:
						_ui_manager.show_overlay("PauseMenu")
						get_tree().paused = true
						get_viewport().set_input_as_handled()


func _on_overlay_closed() -> void:
	_game_manager.return_to_exploration()


func _on_pause_resume_pressed() -> void:
	_ui_manager.hide_overlay("PauseMenu")
	get_tree().paused = false


func _on_return_to_main_menu() -> void:
	if _game_manager.current_state == GameManager.GameState.ENDING:
		get_tree().paused = false
		_ui_manager.show_screen("MainMenu")
		_refresh_main_menu_resume()
		return

	if _exit_confirm_dialog == null:
		_exit_confirm_dialog = ConfirmationDialog.new()
		_exit_confirm_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
		_exit_confirm_dialog.dialog_text = _CONFIRM_EXIT_MESSAGE
		_exit_confirm_dialog.confirmed.connect(_on_exit_confirmed)
		add_child(_exit_confirm_dialog)
	_exit_confirm_dialog.popup_centered()


func _on_exit_confirmed() -> void:
	get_tree().paused = false
	_ui_manager.show_screen("MainMenu")
	_refresh_main_menu_resume()


func _on_adventure_started() -> void:
	_setup_map_ui()


func _on_chapter_started(_chapter: int) -> void:
	_setup_map_ui()


func _setup_map_ui() -> void:
	var map_renderer := _ui_manager.get_screen("MapView") as MapRenderer
	if map_renderer != null:
		map_renderer.initialize(_game_manager.map_state)
		if not map_renderer.node_selected.is_connected(_on_map_node_selected):
			map_renderer.node_selected.connect(_on_map_node_selected)

	if _game_manager.node_manager.player_moved.is_connected(_on_player_moved):
		_game_manager.node_manager.player_moved.disconnect(_on_player_moved)
	_game_manager.node_manager.player_moved.connect(_on_player_moved)

	var backpack_ui := _ui_manager.get_overlay("BackpackUI") as BackpackInterface
	if backpack_ui != null:
		backpack_ui.initialize(_game_manager.backpack_manager)

	_update_map_hud()


func _on_map_node_selected(node_id: StringName) -> void:
	var moved := _game_manager.node_manager.move_to(node_id)
	if moved:
		_update_map_hud()


func _on_player_moved(_to_node_id: StringName, _stamina_cost: int) -> void:
	var map_renderer := _ui_manager.get_screen("MapView") as MapRenderer
	if map_renderer != null:
		map_renderer.refresh_node(_to_node_id)
		for neighbor in _game_manager.map_state.get_neighbors(_to_node_id):
			map_renderer.refresh_node(neighbor.id)
		map_renderer.refresh_connections()
		map_renderer.update_player_marker()
	_update_map_hud()


func _update_map_hud() -> void:
	var map_renderer := _ui_manager.get_screen("MapView") as MapRenderer
	if map_renderer == null:
		return
	var stamina := _game_manager.current_stamina
	map_renderer.update_hud(
		stamina.current_stamina,
		stamina.max_stamina,
		_game_manager.backpack_manager.gold_count,
		_game_manager.current_chapter
	)


func _on_combat_prepared(_combat_manager: CombatManager) -> void:
	_start_combat_ui(_combat_manager)


func _start_combat_ui(combat_manager: CombatManager) -> void:
	var combat_interface := _ui_manager.get_overlay("CombatArena") as CombatInterface
	if combat_interface != null:
		combat_interface.initialize(combat_manager)
		combat_interface.start()


func _on_loot_generated(gold: int, items: Array[ItemData]) -> void:
	_ui_manager.hide_overlay("CombatArena")
	var loot_screen := _ui_manager.get_overlay("LootScreen") as LootScreen
	if loot_screen != null:
		if not loot_screen.loot_taken.is_connected(_on_loot_taken):
			loot_screen.loot_taken.connect(_on_loot_taken)
		if not loot_screen.loot_abandoned.is_connected(_on_loot_abandoned):
			loot_screen.loot_abandoned.connect(_on_loot_abandoned)
		loot_screen.show_loot(gold, items)


func _on_loot_taken(gold: int, items: Array[ItemData]) -> void:
	_game_manager.backpack_manager.add_gold(gold)
	for item in items:
		_game_manager.backpack_manager.add_item(item)
	_game_manager.return_to_exploration()


func _on_loot_abandoned() -> void:
	_game_manager.return_to_exploration()


func _on_player_died() -> void:
	_ui_manager.hide_overlay("CombatArena")
	var ending := _ui_manager.get_overlay("EndingScreen") as EndingScreen
	if ending != null:
		if not ending.return_to_main_menu_pressed.is_connected(_on_return_to_main_menu):
			ending.return_to_main_menu_pressed.connect(_on_return_to_main_menu)
		ending.show_ending(&"death",
			{"narrative": "你倒在了荒野中，再也没有醒来。"}
		)
	_ui_manager.show_overlay("EndingScreen")


func _on_state_changed(new_state: int, _old_state: int) -> void:
	match new_state:
		GameManager.GameState.MAIN_MENU:
			_ui_manager.show_screen("MainMenu")
			_refresh_main_menu_resume()

		GameManager.GameState.MAP_EXPLORATION:
			_ui_manager.show_screen("MapView")
			_ui_manager.hide_overlay("CombatArena")
			var map_renderer := _ui_manager.get_screen("MapView") as MapRenderer
			if map_renderer != null:
				map_renderer.refresh_node(_game_manager.current_combat_node_id)
				var player_node := _game_manager.map_state.get_player_node()
				if player_node != null and player_node.id != _game_manager.current_combat_node_id:
					map_renderer.refresh_node(player_node.id)
				map_renderer.refresh_connections()
				map_renderer.update_player_marker()
			_update_map_hud()

		GameManager.GameState.COMBAT:
			_ui_manager.show_overlay("CombatArena")

		GameManager.GameState.SHOP:
			_ui_manager.show_overlay("ShopOverlay")
			var shop := _ui_manager.get_overlay("ShopOverlay") as ShopInterface
			if shop != null:
				shop.initialize(_game_manager.shop_manager, _game_manager.backpack_manager)

		GameManager.GameState.EVENT:
			_ui_manager.show_overlay("EventOverlay")
			var event_ui := _ui_manager.get_overlay("EventOverlay") as EventInterface
			if event_ui != null:
				event_ui.show_placeholder("事件功能开发中...")

		GameManager.GameState.SAFE_HOUSE:
			_ui_manager.show_overlay("SafeHouse")
			var safe := _ui_manager.get_overlay("SafeHouse") as SafeHouseInterface
			if safe != null:
				var node_id := _game_manager.current_interaction_node_id
				var scholar_stage := _game_manager.survivor_notes.get_entry_completed_stage(&"scholar")
				var state := _game_manager.node_interaction_manager.get_or_create_safe_house_state(node_id, _game_manager.current_chapter, scholar_stage)
				var has_weapon := _game_manager.backpack_manager.equipped_weapon != null
				safe.initialize(state, has_weapon)

		GameManager.GameState.CHAPTER_TRANSITION:
			_ui_manager.show_overlay("ChapterTransition")

		GameManager.GameState.ENDING:
			_ui_manager.show_overlay("EndingScreen")


func _on_safe_house_rest() -> void:
	var stamina := _game_manager.current_stamina
	var deficit := stamina.max_stamina - stamina.current_stamina
	if deficit > 0:
		stamina.restore(deficit)
	_update_map_hud()


func _on_safe_house_item_taken(item: ItemData, _source: StringName) -> void:
	_game_manager.backpack_manager.add_item(item)


func _on_safe_house_gold_taken(amount: int) -> void:
	_game_manager.backpack_manager.add_gold(amount)
	_update_map_hud()


func _on_safe_house_weapon_repaired() -> void:
	# TODO: 接入武器耐久系统（当前无耐久度，先占位）
	pass

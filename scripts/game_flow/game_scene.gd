class_name GameScene
extends Node

@onready var _game_manager: GameManager = $GameManager
@onready var _ui_manager: UIManager = $UIManager

const _CONFIRM_EXIT_MESSAGE: String = "The un-stored progress will be lost. Return to main menu anyway?"
var _fade_tween: Tween
var _exit_confirm_dialog: ConfirmationDialog = null
var _notes_return_target: StringName = &""
var _ruins_choice_callback: Callable
var _ruins_closed_callback: Callable
var _safe_house_closed_cb: Callable

func _ready() -> void:
	_ui_manager.initialize(_game_manager)
	_game_manager.state_changed.connect(_on_state_changed)
	_game_manager.combat_prepared.connect(_on_combat_prepared)
	_game_manager.chapter_started.connect(_on_chapter_started)
	_game_manager.adventure_started.connect(_on_adventure_started)
	_game_manager.adventure_ended.connect(_on_adventure_ended)
	_game_manager.loot_generated.connect(_on_loot_generated)
	_game_manager.ruins_loot_generated.connect(_on_ruins_loot_generated)
	_game_manager.player_died.connect(_on_player_died)
	_game_manager.event_presented.connect(_on_event_presented)
	_game_manager.event_result_presented.connect(_on_event_result_presented)
	_game_manager.password_box_opened.connect(_on_password_box_opened)
	_game_manager.password_box_hint.connect(_on_password_box_hint)
	_game_manager.password_box_reward_granted.connect(_on_password_box_reward_granted)
	_game_manager.stamina_changed.connect(_on_stamina_changed)
	_game_manager.nodes_revealed.connect(_on_nodes_revealed)
	_game_manager.ruins_prompted.connect(_on_ruins_prompted)
	_game_manager.safe_house_denied.connect(_on_safe_house_denied)
	_connect_menu_signals()
	_connect_overlay_signals()
	_connect_save_slot_signals()
	_initialize_survivor_notes_screen()
	_ui_manager.show_screen("MainMenu")


func _initialize_survivor_notes_screen() -> void:
	var notes_screen := _ui_manager.get_screen("SurvivorNotesScreen") as SurvivorNotesScreen
	if notes_screen != null:
		notes_screen.back_pressed.connect(_on_survivor_notes_back_pressed)
		notes_screen.optional_carry_toggled.connect(_on_survivor_notes_optional_carry_toggled)


func _connect_menu_signals() -> void:
	var main_menu: MainMenu = _ui_manager.get_screen("MainMenu")
	if main_menu != null:
		main_menu.difficulty_selected.connect(_on_difficulty_selected)
		main_menu.difficulty_cancelled.connect(_on_difficulty_cancelled)
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


func _on_difficulty_selected(level: int) -> void:
	_game_manager.start_new_adventure(level)


func _on_difficulty_cancelled() -> void:
	pass


func _on_new_adventure_pressed() -> void:
	_game_manager.start_new_adventure()


func _on_continue_pressed() -> void:
	var save_slot_screen := _ui_manager.get_screen("SaveSlotScreen") as SaveSlotScreen
	if save_slot_screen != null:
		save_slot_screen.initialize(_game_manager.save_load_manager)
	_ui_manager.show_screen("SaveSlotScreen")


func _on_settings_pressed() -> void:
	# TODO: show settings panel
	pass


func _on_exit_game_pressed() -> void:
	get_tree().quit()


func _on_survivor_notes_pressed() -> void:
	_notes_return_target = &"MainMenu"
	var notes_screen := _ui_manager.get_screen("SurvivorNotesScreen") as SurvivorNotesScreen
	if notes_screen != null:
		notes_screen.initialize(_game_manager.survivor_notes)
	_ui_manager.show_screen("SurvivorNotesScreen")


func _on_survivor_notes_back_pressed() -> void:
	match _notes_return_target:
		&"SafeHouse":
			_ui_manager.show_screen("MapView")
			_ui_manager.show_overlay("SafeHouse")
		_:
			_ui_manager.show_screen("MainMenu")
	_notes_return_target = &""


func _on_survivor_notes_optional_carry_toggled(enabled: bool) -> void:
	_game_manager.survivor_notes.set_optional_carry(enabled)


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
		event.choice_made.connect(_on_event_choice_made)

	var safe_house := _ui_manager.get_overlay("SafeHouse") as SafeHouseInterface
	if safe_house != null:
		safe_house.closed.connect(_on_overlay_closed)
		safe_house.notes_requested.connect(_on_safe_house_notes_requested)
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
		backpack.closed.connect(_on_backpack_closed)
		backpack.item_use_requested.connect(_on_backpack_item_use_requested)

	if _game_manager.backpack_manager != null:
		_game_manager.backpack_manager.weapon_equipped.connect(_on_weapon_equipped_in_combat)
		_game_manager.backpack_manager.weapon_unequipped.connect(_on_weapon_unequipped_in_combat)

	var password_box := _ui_manager.get_overlay("PasswordBoxScreen") as PasswordBoxScreen
	if password_box != null:
		password_box.guess_submitted.connect(_on_password_guess_submitted)
		password_box.closed.connect(_on_password_box_closed)


func _on_backpack_item_use_requested(item: ItemData, _grid: BackpackGrid) -> void:
	var ok := _game_manager.use_item_in_backpack(item)
	if ok and _game_manager.current_state == GameManager.GameState.COMBAT:
		_ui_manager.hide_overlay("BackpackUI")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B:
				if _game_manager.current_state == GameManager.GameState.MAP_EXPLORATION:
					if _ui_manager.is_overlay_open("BackpackUI"):
						_ui_manager.hide_overlay("BackpackUI")
					else:
						var backpack_ui := _ui_manager.get_overlay("BackpackUI") as BackpackInterface
						if backpack_ui != null:
							backpack_ui.refresh()
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


func _on_backpack_closed() -> void:
	_ui_manager.hide_overlay("BackpackUI")
	if _game_manager.current_state == GameManager.GameState.COMBAT:
		var combat_interface := _ui_manager.get_overlay("CombatArena") as CombatInterface
		if combat_interface != null:
			combat_interface.refresh()
	elif _game_manager.current_state == GameManager.GameState.MAP_EXPLORATION:
		_game_manager.return_to_exploration()


func _on_event_presented(title: String, description: String, choices: Array) -> void:
	var event_ui := _ui_manager.get_overlay("EventOverlay") as EventInterface
	if event_ui != null:
		event_ui.show_event(title, description, choices)


func _on_event_result_presented(title: String, description: String) -> void:
	var event_ui := _ui_manager.get_overlay("EventOverlay") as EventInterface
	if event_ui != null:
		event_ui.show_result(title, description)


func _on_event_choice_made(choice_index: int) -> void:
	_game_manager.resolve_event_choice(choice_index)


func _on_password_box_opened(_item: ItemData, stamina_current: int, stamina_max: int) -> void:
	var pbox := _ui_manager.get_overlay("PasswordBoxScreen") as PasswordBoxScreen
	if pbox != null:
		pbox.show_screen(stamina_current, stamina_max)


func _on_password_guess_submitted(password: int) -> void:
	_game_manager.submit_password_guess(password)


func _on_password_box_hint(hint_text: String) -> void:
	var pbox := _ui_manager.get_overlay("PasswordBoxScreen") as PasswordBoxScreen
	if pbox != null:
		pbox.show_hint(hint_text)


func _on_password_box_reward_granted(reward_desc: String) -> void:
	var pbox := _ui_manager.get_overlay("PasswordBoxScreen") as PasswordBoxScreen
	if pbox != null:
		pbox.show_reward(reward_desc)


func _on_password_box_closed() -> void:
	_ui_manager.hide_overlay("PasswordBoxScreen")


func _on_stamina_changed(current: int, max_stamina: int) -> void:
	_update_map_hud()
	var pbox := _ui_manager.get_overlay("PasswordBoxScreen") as PasswordBoxScreen
	if pbox != null and pbox.visible:
		pbox.update_stamina(current, max_stamina)


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


func _on_nodes_revealed(node_ids: Array[StringName]) -> void:
	var map_renderer := _ui_manager.get_screen("MapView") as MapRenderer
	if map_renderer == null:
		return
	for node_id in node_ids:
		map_renderer.refresh_node(node_id)
	map_renderer.refresh_connections()


func _on_ruins_prompted(node_id: StringName, _search_count: int, stamina_cost: int) -> void:
	var event_ui := _ui_manager.get_overlay("EventOverlay") as EventInterface
	if event_ui == null:
		return

	var desc := "此处是一处废墟，是否消耗 %d 点体力进行搜索？" % stamina_cost
	event_ui.show_event("废墟搜刮", desc, ["搜索", "离开"])

	if event_ui.choice_made.is_connected(_on_event_choice_made):
		event_ui.choice_made.disconnect(_on_event_choice_made)

	_ruins_choice_callback = func(index: int) -> void:
		if event_ui.choice_made.is_connected(_ruins_choice_callback):
			event_ui.choice_made.disconnect(_ruins_choice_callback)
		if event_ui.closed.is_connected(_ruins_closed_callback):
			event_ui.closed.disconnect(_ruins_closed_callback)
		if not event_ui.choice_made.is_connected(_on_event_choice_made):
			event_ui.choice_made.connect(_on_event_choice_made)
		_ui_manager.hide_overlay("EventOverlay")
		if index == 0:
			_game_manager.perform_ruins_search(node_id)

	_ruins_closed_callback = func() -> void:
		if event_ui.choice_made.is_connected(_ruins_choice_callback):
			event_ui.choice_made.disconnect(_ruins_choice_callback)
		if event_ui.closed.is_connected(_ruins_closed_callback):
			event_ui.closed.disconnect(_ruins_closed_callback)
		if not event_ui.choice_made.is_connected(_on_event_choice_made):
			event_ui.choice_made.connect(_on_event_choice_made)

	event_ui.choice_made.connect(_ruins_choice_callback)
	if not event_ui.closed.is_connected(_ruins_closed_callback):
		event_ui.closed.connect(_ruins_closed_callback)
	_ui_manager.show_overlay("EventOverlay")


func _on_safe_house_denied(description: String) -> void:
	var event_ui := _ui_manager.get_overlay("EventOverlay") as EventInterface
	if event_ui == null:
		return

	event_ui.show_result("无法进入", description)

	_safe_house_closed_cb = func() -> void:
		if event_ui.closed.is_connected(_safe_house_closed_cb):
			event_ui.closed.disconnect(_safe_house_closed_cb)
		_ui_manager.hide_overlay("EventOverlay")

	if not event_ui.closed.is_connected(_safe_house_closed_cb):
		event_ui.closed.connect(_safe_house_closed_cb)
	_ui_manager.show_overlay("EventOverlay")


func _on_combat_prepared(_combat_manager: CombatManager) -> void:
	_start_combat_ui(_combat_manager)


func _start_combat_ui(combat_manager: CombatManager) -> void:
	var combat_interface := _ui_manager.get_overlay("CombatArena") as CombatInterface
	if combat_interface != null:
		if not combat_interface.pocket_item_used.is_connected(_on_pocket_item_used):
			combat_interface.pocket_item_used.connect(_on_pocket_item_used)
		if not combat_interface.backpack_open_requested.is_connected(_on_combat_backpack_opened):
			combat_interface.backpack_open_requested.connect(_on_combat_backpack_opened)
		combat_interface.initialize(combat_manager)
		combat_interface.start()


func _on_combat_backpack_opened() -> void:
	var backpack_ui := _ui_manager.get_overlay("BackpackUI") as BackpackInterface
	if backpack_ui != null:
		backpack_ui.refresh()
	_ui_manager.show_overlay("BackpackUI")


func _on_weapon_equipped_in_combat(_weapon: ItemData) -> void:
	if _game_manager.current_state == GameManager.GameState.COMBAT:
		if _ui_manager.is_overlay_open("BackpackUI"):
			_ui_manager.hide_overlay("BackpackUI")


func _on_weapon_unequipped_in_combat(_weapon: ItemData) -> void:
	pass


func _on_pocket_item_used(item_id: StringName) -> void:
	_game_manager.notify_consumable_used(item_id, true)


func _on_loot_generated(gold: int, items: Array[ItemData]) -> void:
	_ui_manager.hide_overlay("CombatArena")
	var loot_screen := _ui_manager.get_overlay("LootScreen") as LootScreen
	if loot_screen != null:
		_disconnect_all_loot_handlers(loot_screen)
		loot_screen.loot_taken.connect(_on_loot_taken)
		loot_screen.loot_abandoned.connect(_on_loot_abandoned)
		loot_screen.set_title("战斗胜利！")
		loot_screen.show_loot(gold, items)


func _on_ruins_loot_generated(gold: int, items: Array[ItemData]) -> void:
	var loot_screen := _ui_manager.get_overlay("LootScreen") as LootScreen
	if loot_screen != null:
		_disconnect_all_loot_handlers(loot_screen)
		loot_screen.loot_taken.connect(_on_ruins_loot_dismissed)
		loot_screen.loot_abandoned.connect(_on_ruins_loot_abandoned)
		loot_screen.set_title("废墟搜刮")
		loot_screen.show_loot(gold, items)


func _disconnect_all_loot_handlers(loot_screen: LootScreen) -> void:
	if loot_screen.loot_taken.is_connected(_on_loot_taken):
		loot_screen.loot_taken.disconnect(_on_loot_taken)
	if loot_screen.loot_taken.is_connected(_on_ruins_loot_dismissed):
		loot_screen.loot_taken.disconnect(_on_ruins_loot_dismissed)
	if loot_screen.loot_abandoned.is_connected(_on_loot_abandoned):
		loot_screen.loot_abandoned.disconnect(_on_loot_abandoned)
	if loot_screen.loot_abandoned.is_connected(_on_ruins_loot_abandoned):
		loot_screen.loot_abandoned.disconnect(_on_ruins_loot_abandoned)


func _on_loot_taken(gold: int, items: Array[ItemData]) -> void:
	_game_manager.backpack_manager.add_gold(gold)
	for item in items:
		_game_manager.backpack_manager.add_item(item)
	_game_manager.return_to_exploration()


func _on_loot_abandoned() -> void:
	_game_manager.return_to_exploration()


func _on_ruins_loot_dismissed(_gold: int, _items: Array[ItemData]) -> void:
	_game_manager.return_to_exploration()


func _on_ruins_loot_abandoned() -> void:
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


func _on_adventure_ended(ending_type: StringName) -> void:
	if ending_type == &"victory":
		_ui_manager.hide_overlay("CombatArena")
		var ending := _ui_manager.get_overlay("EndingScreen") as EndingScreen
		if ending != null:
			if not ending.return_to_main_menu_pressed.is_connected(_on_return_to_main_menu):
				ending.return_to_main_menu_pressed.connect(_on_return_to_main_menu)
			ending.show_ending(&"victory",
				{"narrative": "You have defeated the boss and cleared this area."}
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
			_ui_manager.hide_overlay("EventOverlay")
			_ui_manager.show_overlay("CombatArena")

		GameManager.GameState.SHOP:
			_ui_manager.show_overlay("ShopOverlay")
			var shop := _ui_manager.get_overlay("ShopOverlay") as ShopInterface
			if shop != null:
				shop.initialize(_game_manager.shop_manager, _game_manager.backpack_manager)

		GameManager.GameState.EVENT:
			_ui_manager.show_overlay("EventOverlay")

		GameManager.GameState.SAFE_HOUSE:
			_ui_manager.show_overlay("SafeHouse")
			var safe := _ui_manager.get_overlay("SafeHouse") as SafeHouseInterface
			if safe != null:
				var node_id := _game_manager.current_interaction_node_id
				var scholar_stage := _game_manager.survivor_notes.get_entry_completed_stage(&"scholar")
				var state := _game_manager.node_interaction_manager.get_or_create_safe_house_state(node_id, _game_manager.current_chapter, scholar_stage)
				var equipped_weapon := _game_manager.backpack_manager.equipped_weapon
				safe.initialize(state, equipped_weapon)

		GameManager.GameState.CHAPTER_TRANSITION:
			_ui_manager.show_overlay("ChapterTransition")

		GameManager.GameState.ENDING:
			_ui_manager.show_overlay("EndingScreen")


func _on_safe_house_notes_requested() -> void:
	_notes_return_target = &"SafeHouse"
	var notes_screen := _ui_manager.get_screen("SurvivorNotesScreen") as SurvivorNotesScreen
	if notes_screen != null:
		notes_screen.initialize(_game_manager.survivor_notes)
	_ui_manager.show_screen("SurvivorNotesScreen")


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
	var wpn := _game_manager.backpack_manager.equipped_weapon
	if wpn == null or wpn.weapon_data == null:
		return
	if wpn.is_chainsaw():
		return
	wpn.weapon_current_durability = wpn.get_weapon_max_durability()
	var safe_house := _ui_manager.get_overlay("SafeHouseUI") as SafeHouseInterface
	if safe_house != null:
		safe_house.initialize(_game_manager.node_interaction_manager.get_or_create_safe_house_state(
			_game_manager.current_interaction_node_id,
			_game_manager.current_chapter,
			_game_manager.survivor_notes.get_scholar_stage()
		), wpn)
	_update_map_hud()

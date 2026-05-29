class_name GameScene
extends Node

@onready var _game_manager: GameManager = $GameManager
@onready var _ui_manager: UIManager = $UIManager

var _fade_tween: Tween

func _ready() -> void:
	_ui_manager.initialize(_game_manager)
	_game_manager.state_changed.connect(_on_state_changed)
	_game_manager.combat_prepared.connect(_on_combat_prepared)
	_game_manager.chapter_started.connect(_on_chapter_started)
	_game_manager.loot_generated.connect(_on_loot_generated)
	_game_manager.player_died.connect(_on_player_died)
	_connect_menu_signals()
	_connect_overlay_signals()
	_ui_manager.show_screen("MainMenu")


func _connect_menu_signals() -> void:
	var main_menu: MainMenu = _ui_manager.get_screen("MainMenu")
	if main_menu != null:
		main_menu.new_adventure_pressed.connect(_on_new_adventure_pressed)
		main_menu.continue_pressed.connect(_on_continue_pressed)
		main_menu.survivor_notes_pressed.connect(_on_survivor_notes_pressed)
		main_menu.settings_pressed.connect(_on_settings_pressed)


func _on_new_adventure_pressed() -> void:
	_game_manager.start_new_adventure()


func _on_continue_pressed() -> void:
	# TODO: load save via save_load_manager
	pass


func _on_survivor_notes_pressed() -> void:
	# TODO: show survivor notes screen
	pass


func _on_settings_pressed() -> void:
	# TODO: show settings panel
	pass


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

	var pause := _ui_manager.get_overlay("PauseMenu") as PauseMenu
	if pause != null:
		pause.resume_pressed.connect(_on_overlay_closed)
		pause.return_to_main_menu_pressed.connect(_on_return_to_main_menu)

	var chapter := _ui_manager.get_overlay("ChapterTransition") as ChapterTransition
	if chapter != null:
		chapter.dismissed.connect(_on_overlay_closed)

	var ending := _ui_manager.get_overlay("EndingScreen") as EndingScreen
	if ending != null:
		ending.return_to_main_menu_pressed.connect(_on_return_to_main_menu)


func _on_overlay_closed() -> void:
	_game_manager.return_to_exploration()


func _on_return_to_main_menu() -> void:
	_ui_manager.show_screen("MainMenu")


func _on_chapter_started(_chapter: int) -> void:
	var map_renderer := _ui_manager.get_screen("MapView") as MapRenderer
	if map_renderer != null:
		map_renderer.initialize(_game_manager.map_state)
		if not map_renderer.node_selected.is_connected(_on_map_node_selected):
			map_renderer.node_selected.connect(_on_map_node_selected)

	if _game_manager.node_manager.player_moved.is_connected(_on_player_moved):
		_game_manager.node_manager.player_moved.disconnect(_on_player_moved)
	_game_manager.node_manager.player_moved.connect(_on_player_moved)

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
		0,  # TODO: gold from backpack_manager
		_game_manager.current_chapter
	)


func _on_combat_prepared(_combat_manager: CombatManager) -> void:
	var combat_interface := _ui_manager.get_overlay("CombatArena") as CombatInterface
	if combat_interface != null:
		combat_interface.initialize(_combat_manager)
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
				shop.show_placeholder("黑市功能开发中...")

		GameManager.GameState.EVENT:
			_ui_manager.show_overlay("EventOverlay")
			var event_ui := _ui_manager.get_overlay("EventOverlay") as EventInterface
			if event_ui != null:
				event_ui.show_placeholder("事件功能开发中...")

		GameManager.GameState.SAFE_HOUSE:
			_ui_manager.show_overlay("SafeHouse")
			var safe := _ui_manager.get_overlay("SafeHouse") as SafeHouseInterface
			if safe != null:
				safe.show_placeholder("安全屋功能开发中...")

		GameManager.GameState.CHAPTER_TRANSITION:
			_ui_manager.show_overlay("ChapterTransition")

		GameManager.GameState.ENDING:
			_ui_manager.show_overlay("EndingScreen")

extends SceneTree

func _init() -> void:
	# Core data
	var _item_data := ItemData.new()
	var _map_node_data := MapNodeData.new()
	var _map_state := MapState.new()

	# Map system
	var _map_gen := MapGenerator.new()
	var _path_finder := PathFinder.new()
	var _node_mgr := NodeManager.new()
	var _node_interact := NodeInteractionManager.new()

	# Backpack system
	var _backpack_grid := BackpackGrid.new()
	var _backpack_mgr := BackpackManager.new()
	var _item_org := ItemOrganizer.new()

	# Survival
	var _relic_hdl := RelicHandler.new()
	var _survivor_notes := SurvivorNotes.new()

	# Shop / Events / Quest
	var _shop_mgr := ShopManager.new()
	var _event_mgr := EventManager.new()
	var _quest_mgr := QuestManager.new()

	# Save/Load & Ending
	var _adv_res := AdventureStateResource.new()
	var _meta_res := MetaStateResource.new()
	var _save_slot := SaveSlotResource.new()
	var _save_load := SaveLoadManager.new()
	var _ending_mgr := EndingManager.new()

	# GameManager (Node-based, needs tree)
	var gm_script := preload("res://scripts/game_flow/game_manager.gd")
	var _game_mgr := gm_script.new()
	get_root().add_child(_game_mgr)

	print("All classes compiled successfully")
	quit()

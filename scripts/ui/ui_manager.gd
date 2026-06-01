class_name UIManager
extends CanvasLayer

var _game_manager: GameManager

var _screens: Dictionary = {}
var _overlays: Dictionary = {}

func initialize(game_manager: GameManager) -> void:
	_game_manager = game_manager
	_discover_children()


func _discover_children() -> void:
	for child in get_children():
		var name := child.name
		if child is Control or child is CanvasLayer:
			if name.ends_with("Overlay") or name in ["SafeHouse", "ChapterTransition", "EndingScreen", "PauseMenu", "CombatArena", "LootScreen", "BackpackUI"]:
				_overlays[name] = child
				child.visible = false
			else:
				_screens[name] = child
				child.visible = false


func get_screen(screen_name: String) -> Node:
	return _screens.get(screen_name)


func get_overlay(overlay_name: String) -> Node:
	return _overlays.get(overlay_name)


func show_screen(screen_name: String) -> void:
	for name in _screens:
		var screen: Node = _screens[name]
		screen.visible = name == screen_name
	_hide_all_overlays()


func show_overlay(overlay_name: String) -> void:
	var overlay: Node = _overlays.get(overlay_name)
	if overlay != null:
		overlay.visible = true


func hide_overlay(overlay_name: String) -> void:
	var overlay: Node = _overlays.get(overlay_name)
	if overlay != null:
		overlay.visible = false


func _hide_all_overlays() -> void:
	for overlay in _overlays.values():
		overlay.visible = false


func is_overlay_open(overlay_name: String) -> bool:
	var overlay: Node = _overlays.get(overlay_name)
	return overlay != null and overlay.visible

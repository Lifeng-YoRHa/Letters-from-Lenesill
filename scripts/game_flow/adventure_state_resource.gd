class_name AdventureStateResource
extends Resource

@export var chapter: int = 1
@export var player_node_id: StringName = &""
@export var nodes: Array[MapNodeData] = []
@export var combat_snapshot: Dictionary = {}
@export var stamina_current: int = 0
@export var stamina_max: int = 0
@export var gold: int = 0
@export var backpack_type: StringName = &"satchel"
@export var backpack_items: Array[Dictionary] = []  # {item_id, grid_type, x, y, rotated}
@export var pocket_items: Array[Dictionary] = []
@export var equipped_weapon_id: StringName = &""
@export var held_relics: Array[StringName] = []
@export var used_once_relics: Array[StringName] = []
@export var adrenaline_needle_used: bool = false
@export var survivors_letter_count: int = 0
@export var quest_state: int = 0
@export var quest_node_id: StringName = &""
@export var lost_letter_location_id: StringName = &""
@export var shop_stock: Array[Dictionary] = []
@export var event_assignments: Dictionary = {}
@export var ruins_search_counters: Dictionary = {}
@export var boss_hp: int = 0
@export var boss_emergency_heal_used: bool = false

class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String
@export var enemy_type: GameEnums.EnemyType
@export var chapter: int
@export var base_hp: int
@export var base_attack: int
@export var special_mechanic_id: StringName
@export var assigned_debuffs: Array[GameEnums.DebuffType]
@export var loot_table: LootTable
@export var mechanic_params: Dictionary = {}
@export var spawn_weight: float

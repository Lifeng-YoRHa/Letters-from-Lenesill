class_name MapNodeData
extends Resource

@export var id: StringName
@export var node_type: GameEnums.MapNodeType
@export var event_type: StringName = &""
@export var layer: int
@export var slot_index: int
@export var connections: Array[StringName] = []
@export var position: Vector2
@export var visibility: GameEnums.MapNodeVisibility = GameEnums.MapNodeVisibility.UNEXPLORED


func get_slot_name() -> String:
	return "L%d_%d" % [layer, slot_index]

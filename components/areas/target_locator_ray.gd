extends RayCast2D
class_name TargetLocatorRay

var player_node : Node2D


func _ready():
	player_node = get_tree().get_first_node_in_group("player")


func has_target() -> bool:
	if not player_node:
		return false
	
	target_position = player_node.global_position - owner.global_position
	force_raycast_update()
	
	if get_collider() is TileMap:
		return false
	
	return true

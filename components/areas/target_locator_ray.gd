extends RayCast2D
class_name TargetLocatorRay

var target : Node2D


func set_target(new_target : Node2D):
	target = new_target


func has_target() -> bool:
	if not target:
		return false
	
	target_position = target.global_position - global_position
	force_raycast_update()
	
	if get_collider() is TileMap:
		return false
	
	return true

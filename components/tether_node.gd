extends Pickup
class_name TetherNode

@onready var line : Line2D = $Line2D
@onready var ray : RayCast2D = $RayCast2D

var player : Player


func _physics_process(delta):
	if not player:
		return
	
	check_ray(player)


func check_ray(target):
	var direction = target.global_position - global_position
	ray.target_position = direction
	ray.force_raycast_update()
	
	if ray.is_colliding():
		line.set_point_position(1, Vector2.ZERO)
		return
		
	line.set_point_position(1, ray.target_position)


func show_details():
	if not player:
		return
	
	super.show_details()


func interact():
	if not player:
		return
	
	super.interact()

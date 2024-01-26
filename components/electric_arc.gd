extends Line2D
class_name ElectricArc

@export var time_between_zaps : float

@onready var ray : RayCast2D = $RayCast2D
@onready var hitbox : Hitbox = $Hitbox
@onready var timer : Timer = $Timer

var target : Node2D


func set_target(new_target : Node2D):
	target = new_target


func set_enabled(value : bool):
	visible = value
	hitbox.collision_shape.set_deferred("disabled", !value)


func _physics_process(_delta):
	if not target:
		return
	
	ray.target_position = target.global_position - global_position
	ray.force_raycast_update()
	set_point_position(1, ray.target_position)
	hitbox.position = ray.target_position / 2
	hitbox.rotation = ray.target_position.angle()
	var hitbox_size = (get_point_position(0) + ray.target_position).length() / 2
	hitbox.collision_shape.shape.extents = Vector2(hitbox_size, 2)


func _on_hitbox_area_entered(_area):
	hitbox.collision_shape.set_deferred("disabled", true)
	timer.start(time_between_zaps)


func _on_timer_timeout():
	hitbox.collision_shape.set_deferred("disabled", false)

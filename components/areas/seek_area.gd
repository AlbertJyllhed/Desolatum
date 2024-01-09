extends Area2D

@export var projectile : Projectile
@export var turn_speed : float = 20.0

@onready var ray : RayCast2D = $RayCast2D

var target : Node2D


func _physics_process(delta):
	if not is_instance_valid(target):
		return
	
	ray.target_position = (target.global_position - global_position).normalized() * 64
	ray.force_raycast_update()
	
	if ray.is_colliding():
		if ray.get_collider() is TileMap:
			return
	
	var direction = (target.global_position - global_position).normalized()
	projectile.direction = projectile.direction.move_toward(direction, turn_speed * delta)
	projectile.sprite.rotation = projectile.direction.angle()


func _on_body_entered(body):
	if target:
		return
	
	target = body


func _on_body_exited(_body):
	target = null

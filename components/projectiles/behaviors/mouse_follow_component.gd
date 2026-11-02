extends Node2D

@export var projectile : Projectile
@export var turn_speed : float = 10.0


func _physics_process(delta):
	var direction = (get_global_mouse_position() - global_position).normalized()
	projectile.direction = projectile.direction.move_toward(direction, turn_speed * delta)
	projectile.sprite.rotation = projectile.direction.angle()

extends Node2D

## Steers the projectile toward its shooter's aim point (mouse or gamepad).
## Does nothing for projectiles fired without an aim source (turrets, enemies).

@export var projectile : Projectile
@export var turn_speed : float = 10.0


func _physics_process(delta):
	if not is_instance_valid(projectile.aim_source):
		return
	
	var aim_point : Vector2 = projectile.aim_source.get_aim_direction()
	var direction = (aim_point - global_position).normalized()
	projectile.direction = projectile.direction.move_toward(direction, turn_speed * delta)
	projectile.sprite.rotation = projectile.direction.angle()

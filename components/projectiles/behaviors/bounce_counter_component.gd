extends Node

@export var projectile : Projectile

var base_size : float = 1.0


func _ready():
	if not projectile:
		return
	
	projectile.wall_hit.connect(on_wall_hit)


func on_wall_hit():
	base_size = min(base_size + 1, 3)
	projectile.sprite.scale = Vector2(base_size, base_size)
	projectile.hitbox.damage = int(base_size)

extends Node

@export var projectile : Projectile

var base_size : float = 1.0


func _ready():
	if not projectile:
		return
	
	projectile.wall_hit.connect(on_wall_hit)


func on_wall_hit():
	var size = min(base_size + 1, 3)
	projectile.sprite.scale = Vector2(size, size)
	projectile.hitbox.damage = size

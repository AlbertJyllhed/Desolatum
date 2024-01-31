extends Node

@export var projectile : Projectile

var base_size : float = 1.0


func _ready():
	if not projectile:
		return
	
	projectile.ready.connect(setup)


func setup():
	projectile.hitbox.area_exited.connect(on_enemy_hit)


func on_enemy_hit(_area):
	projectile.hitbox.damage += 1
	var size = min(base_size * 1.1, 1.5)
	projectile.sprite.scale = Vector2(size, size)

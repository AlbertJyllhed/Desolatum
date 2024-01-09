extends Node

@export var projectile : Projectile


func _ready():
	if not projectile:
		return
	
	projectile.ready.connect(setup)


func setup():
	projectile.hitbox.area_exited.connect(on_enemy_hit)


func on_enemy_hit(_area):
	projectile.bounces += 1
	projectile.hitbox.damage += 1
	projectile.sprite.scale *= 1.1

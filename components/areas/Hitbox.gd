extends Area2D
class_name Hitbox

@export var damage : int = 1
var knockback_vector = Vector2.ZERO


func set_damage(newDamage):
	damage = newDamage

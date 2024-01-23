extends Area2D
class_name Hitbox

@export var damage : int = 1

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

var knockback_vector = Vector2.ZERO


func set_damage(new_damage : int):
	damage = new_damage

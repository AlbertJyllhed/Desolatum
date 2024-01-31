extends Area2D
class_name Hitbox

@export var damage : int = 1
@export_range(1.0, 3.0, 0.1, "or_greater") var knockback_multiplier : float = 1.0
@export_range(0.1, 3.0, 0.1, "or_greater") var stun_time : float = 0.2

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

var knockback_vector = Vector2.ZERO


func set_damage(new_damage : int):
	damage = new_damage

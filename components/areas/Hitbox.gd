extends Area2D
class_name Hitbox

@export var damage : int = 1
@export_range(1.0, 3.0, 0.1, "or_greater") var knockback_multiplier : float = 1.0
@export_range(0.1, 3.0, 0.1, "or_greater") var stun_time : float = 0.2
## Freezes the game this many seconds whenever this hitbox damages something
## (e.g. 0.05 for melee, 0.08 for explosions). 0 = no hit stop.
@export_range(0.0, 0.3, 0.01) var hit_stop : float = 0.0
## Damage each target only once during this hitbox's life (melee swings,
## explosions). Off = the target's damage_tick_delay decides when it can be hit again.
@export var hit_once : bool = false

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

var knockback_vector = Vector2.ZERO


func set_damage(new_damage : int):
	damage = new_damage

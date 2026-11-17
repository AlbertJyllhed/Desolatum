extends Node

@export var hurtbox : Hurtbox
@export var hit_effect_scene : PackedScene
@export var offset : Vector2 = Vector2(0, -8)


func _ready():
	hurtbox.hit.connect(on_hit)


func on_hit(knockback_vector : Vector2, _knockback_time : float):
	var owner_node = owner as Node2D
	Pool.spawn(hit_effect_scene, owner_node, owner_node.global_position + offset, knockback_vector.angle())

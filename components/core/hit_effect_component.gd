extends Node

@export var hurtbox : Hurtbox
@export var hit_effect_scene : PackedScene
@export var offset : Vector2 = Vector2(0, -8)


func _ready():
	hurtbox.hit.connect(on_hit)


func on_hit(knockback_vector : Vector2, _knockback_time : float):
	var owner_node = owner as Node2D
	var hit_effect_instance = hit_effect_scene.instantiate() as Node2D
	owner_node.add_child(hit_effect_instance)
	hit_effect_instance.global_position = owner_node.global_position + offset
	hit_effect_instance.rotation = knockback_vector.angle()

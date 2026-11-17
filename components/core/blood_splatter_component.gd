extends Node

@export var health_component : HealthComponent
@export var blood_splatter_scene : PackedScene
@export var blood_color : Color

var base_layer : Node2D


func _ready():
	health_component.damaged.connect(on_damaged)
	base_layer = get_tree().get_first_node_in_group("base_layer")


func on_damaged(_amount : float) -> void:
	var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
	var spawn_position = (owner as Node2D).global_position + offset
	var blood_splatter_instance := Pool.spawn(blood_splatter_scene, base_layer, spawn_position, deg_to_rad(randf_range(-180, 180))) as Node2D
	blood_splatter_instance.modulate = blood_color

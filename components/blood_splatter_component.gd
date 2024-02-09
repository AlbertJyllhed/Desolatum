extends Node

@export var health_component : HealthComponent
@export var blood_splatter_scene : PackedScene
@export var blood_color : Color

var base_layer : Node2D


func _ready():
	health_component.health_changed.connect(on_health_changed)
	base_layer = get_tree().get_first_node_in_group("base_layer")


func on_health_changed(health : float):
	var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
	var spawn_position = (owner as Node2D).global_position + offset
	var blood_splatter_instance = blood_splatter_scene.instantiate() as Node2D
	base_layer.add_child(blood_splatter_instance)
	blood_splatter_instance.global_position = spawn_position
	blood_splatter_instance.rotation_degrees = randf_range(-180, 180)
	blood_splatter_instance.modulate = blood_color

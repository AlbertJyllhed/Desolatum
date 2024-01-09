extends Node2D

@export var explosion_scene : PackedScene

var old_position : Vector2


func teleport(node_to_teleport : Node2D):
	#teleport the player and save their old position
	old_position = node_to_teleport.global_position
	node_to_teleport.global_position = global_position
	
	#create explosion at old player position
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	var explosion_instance = explosion_scene.instantiate() as Node2D
	base_layer.add_child(explosion_instance)
	explosion_instance.global_position = old_position
	
	queue_free()

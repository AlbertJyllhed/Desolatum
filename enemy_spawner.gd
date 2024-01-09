extends Node2D
class_name EnemySpawner

signal done_spawning

@onready var sprite : Sprite2D = $Sprite2D

var light : Node2D


func spawn_enemy(enemy_scene : PackedScene):
	if light:
		return
	
	var enemy_instance = enemy_scene.instantiate() as Node2D
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	base_layer.call_deferred("add_child", enemy_instance)
	enemy_instance.global_position = global_position
	done_spawning.emit()


func _on_area_2d_area_entered(area):
	light = area.owner
	sprite.modulate = Color.BLACK


func _on_area_2d_area_exited(_area):
	light = null
	sprite.modulate = Color.WHITE

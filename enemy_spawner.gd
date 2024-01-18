extends Node2D
class_name EnemySpawner

@onready var sprite : Sprite2D = $Sprite2D

var lights : Array[Node2D]


func spawn_enemy(enemy_scene : PackedScene, is_aggressive : bool = false):
	if lights.size() > 0:
		return
	
	var enemy_instance = enemy_scene.instantiate() as Node2D
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	base_layer.call_deferred("add_child", enemy_instance)
	enemy_instance.global_position = global_position
	enemy_instance.aggressive = is_aggressive


func _on_area_2d_area_entered(area):
	lights.append(area.owner)
	sprite.modulate = Color.BLACK


func _on_area_2d_area_exited(area):
	lights.erase(area.owner)
	if lights.size() > 0:
		return
	
	sprite.modulate = Color.WHITE

extends StaticBody2D

@export var explode_time : float = 1.0

@onready var timer : Timer = $Timer


func _on_target_locator_area_body_entered(body):
	timer.start(explode_time)


func _on_timer_timeout():
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	var explosion_scene = preload("res://particles/explosion.tscn")
	var explosion_instance = explosion_scene.instantiate()
	base_layer.call_deferred("add_child", explosion_instance)
	explosion_instance.global_position = global_position
	queue_free()

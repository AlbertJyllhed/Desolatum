extends Area2D

@onready var particles : GPUParticles2D = $GPUParticles2D
@onready var timer : Timer = $Timer

var rock_fall_scene : PackedScene = preload("res://particles/rock_fall.tscn")


func _on_body_entered(body):
	particles.emitting = true
	timer.start()


func _on_timer_timeout():
	#make a big rock fall down on the ground
	var foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
	var rock_fall_instance = rock_fall_scene.instantiate()
	foreground_layer.add_child(rock_fall_instance)
	rock_fall_instance.global_position = global_position
	queue_free()

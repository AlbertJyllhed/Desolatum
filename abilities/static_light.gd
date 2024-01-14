extends Node2D

@export var speed : float = 10.0

var target_position : Vector2


func set_target_position(position : Vector2):
	target_position = position


func _physics_process(delta):
	position = position.lerp(target_position, 0.1)

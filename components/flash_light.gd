extends Node2D

@export var light_distance : float = 16.0

@onready var light : Node2D = $Light
@onready var proximity_sensor : Area2D = $ProximitySensorArea


func _physics_process(_delta):
	var direction = get_local_mouse_position().normalized()
	light.position = light.position.lerp(direction * light_distance, 0.1)

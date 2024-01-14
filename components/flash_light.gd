extends Node2D

@export var static_light_scene : PackedScene
@export var light_distance : float = 16.0

@onready var light : Node2D = $Light

var base_layer : Node2D
var static_light_instance : Node2D


func _ready():
	base_layer = get_tree().get_first_node_in_group("base_layer")


func _physics_process(_delta):
	if Input.is_action_just_pressed("flashlight"):
		light.visible = !light.visible
		send_to_position(light.visible)
	
	var direction = get_local_mouse_position().normalized()
	light.position = light.position.lerp(direction * light_distance, 0.1)


func send_to_position(value : bool):
	if value:
		static_light_instance.queue_free()
		return
	
	static_light_instance = static_light_scene.instantiate()
	base_layer.add_child(static_light_instance)
	static_light_instance.global_position = global_position
	static_light_instance.set_target_position(get_global_mouse_position())

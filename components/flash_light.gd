extends Node2D
class_name FlashLight

#@export var light_distance : float = 16.0

@onready var light : Light2D = $Light
@onready var proximity_sensor : ProximitySensor = $ProximitySensorArea


func _physics_process(delta):
	if Input.is_action_just_pressed("flashlight"):
		toggle_light()
	
	#if not light.enabled:
		#return
	#
	#var direction = get_local_mouse_position().normalized()
	#light.position = light.position.lerp(direction * light_distance, 0.1)


func toggle_light():
	light.enabled = !light.enabled
	proximity_sensor.enable_alarm(!light.enabled)
	print(proximity_sensor.alarm_enabled)

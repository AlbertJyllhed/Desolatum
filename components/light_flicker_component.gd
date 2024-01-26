extends PointLight2D

@export var light_size : float = 0.7
@export var base_size_change_speed : float = 0.1

var max_light_size : float = 0.7
var min_light_size : float = 0.69
var size_change_speed : float


func _ready():
	size_change_speed = base_size_change_speed


func _physics_process(delta):
	light_size += size_change_speed * delta
	if light_size >= max_light_size:
		size_change_speed *= -1
	if light_size <= min_light_size:
		size_change_speed = base_size_change_speed
	
	light_size = clampf(light_size, min_light_size, max_light_size)
	texture_scale = lerp(texture_scale, light_size, 1.0)

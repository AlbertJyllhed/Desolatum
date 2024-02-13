extends Camera2D
class_name PlayerCamera

var target : Node2D
var target_position : Vector2
var padding : int = 50

var shake_vector : Vector2
var shake_offset : Vector2
var shake_magnitude : float
var shake_time_end : float
var shaking : bool


func _ready():
	GameEvents.set_camera_target.connect(set_target)


func set_target(new_target : Node2D):
	target = new_target


func update_target_position():
	if not is_instance_valid(target):
		return position
	
	if not target is Player:
		return target.position
	
	var mouse_position = get_local_mouse_position()
	if GamepadManager.using_gamepad:
		mouse_position = GamepadManager.get_aim_direction() * 16
	
	mouse_position.x = clamp(mouse_position.x, -padding, padding)
	mouse_position.y = clamp(mouse_position.y, -padding, padding)
	
	var ret = target.position + mouse_position
	ret += shake_offset
	ret = round(ret)
	return ret


func _physics_process(delta):
	shake_offset = update_shake()
	target_position = update_target_position()
	position = lerp(position, target_position, 20.0 * delta).round()


func shake(direction : Vector2, magnitude : float, length : float):
	shaking = true
	shake_vector = direction
	shake_magnitude = magnitude
	shake_time_end = Time.get_ticks_msec() + (length * 10)


func random_shake(magnitude : float, length : float):
	shaking = true
	shake_vector = get_random_offset(magnitude)
	shake_magnitude = magnitude
	shake_time_end = Time.get_ticks_msec() + (length * 10)


func get_random_offset(magnitude : float) -> Vector2:
	return Vector2(
		randf_range(-magnitude, magnitude),
		randf_range(-magnitude, magnitude)
	)


func update_shake():
	if not shaking or Time.get_ticks_msec() > shake_time_end:
		shaking = false
		return Vector2.ZERO
	
	var temp_offset : Vector2 = shake_vector
	temp_offset *= shake_magnitude
	return temp_offset

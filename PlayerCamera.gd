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


func set_target(new_target : Node2D):
	target = new_target


func update_target_position():
	var mouse_position = get_local_mouse_position()
	mouse_position.x = clamp(mouse_position.x, -padding, padding)
	mouse_position.y = clamp(mouse_position.y, -padding, padding)
	
	if not is_instance_valid(target):
		return position
	
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


func update_shake():
	if not shaking or Time.get_ticks_msec() > shake_time_end:
		shaking = false
		return Vector2.ZERO
	
	var temp_offset : Vector2 = shake_vector
	temp_offset *= shake_magnitude
	return temp_offset

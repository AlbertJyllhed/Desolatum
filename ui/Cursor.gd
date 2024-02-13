extends Control

var screen_center : Vector2


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	screen_center = get_viewport_rect().size / 2


func _process(delta):
	global_position = get_global_mouse_position()
	if GamepadManager.using_gamepad:
		global_position = screen_center + GamepadManager.get_aim_direction() * 16

extends Control

var screen_center : Vector2


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	get_window().size_changed.connect(on_window_size_changed)
	screen_center = get_viewport_rect().size / 2


func on_window_size_changed():
	screen_center = get_viewport_rect().size / 2


func _process(delta):
	global_position = get_global_mouse_position()
	if GamepadManager.using_gamepad:
		global_position = screen_center + GamepadManager.get_aim_direction()

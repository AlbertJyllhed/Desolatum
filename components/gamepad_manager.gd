extends Node

var using_gamepad : bool = false


func _unhandled_input(event):
	if event is InputEventJoypadMotion:
		if event.axis_value < -0.4 or event.axis_value > 0.4:
			using_gamepad = true
	
	if event is InputEventJoypadButton:
		using_gamepad = true
	
	if event is InputEventMouse or event is InputEventKey:
		using_gamepad = false


func get_aim_direction() -> Vector2:
	var direction : Vector2
	direction.x = Input.get_axis("aim_left", "aim_right")
	direction.y = Input.get_axis("aim_up", "aim_down")
	return direction.normalized()

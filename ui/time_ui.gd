extends Control
class_name TimeUI

@onready var label : Label = $Label
@onready var timer : Timer = $Timer

func _process(_delta):
	label.text = format_seconds(timer.time_left)


func format_seconds(time : float):
	var minutes = time / 60
	var seconds = fmod(time, 60)
	#var milliseconds = fmod(time, 1) * 100
	return "%02d:%02d" % [minutes, seconds]

extends Area2D
class_name TargetLocatorArea

@export var min_reset_time : float = 2.0
@export var max_reset_time : float = 3.0

@onready var reset_timer : Timer = $ResetTimer


func deactivate_detection():
	set_deferred("monitoring", false)
	var reset_time = randf_range(min_reset_time, max_reset_time)
	reset_timer.start(reset_time)


func _on_reset_timer_timeout():
	set_deferred("monitoring", true)

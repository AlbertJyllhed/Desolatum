extends Area2D
class_name ProximitySensor

@onready var audio_stream_player : AudioStreamPlayer2D = $AudioStreamPlayer2D

var alarm_enabled : bool = false


func enable_alarm(value : bool):
	alarm_enabled = value


func _on_body_entered(_body):
	if not alarm_enabled:
		return
	
	audio_stream_player.play()

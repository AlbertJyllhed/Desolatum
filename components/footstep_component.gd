extends Node
class_name FootstepComponent

@onready var audio_player_component : AudioPlayerComponent = $AudioPlayerComponent
@onready var timer : Timer = $Timer


func start_footsteps():
	if timer.is_stopped():
		timer.start()


func stop_footsteps():
	timer.stop()


func _on_timer_timeout():
	audio_player_component.play_random_sound()

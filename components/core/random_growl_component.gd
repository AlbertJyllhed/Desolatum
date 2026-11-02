extends Node

@export var min_growl_time : float = 10.0
@export var max_growl_time : float = 30.0

@onready var audio_player_component : AudioPlayerComponent = $AudioPlayerComponent
@onready var timer : Timer = $Timer


func _ready():
	timer.start(randf_range(min_growl_time, max_growl_time))


func _on_timer_timeout():
	audio_player_component.play_random_sound()
	timer.start(randf_range(min_growl_time, max_growl_time))

extends Node
class_name AudioPlayerComponent

@export var volume_modifier : float = 0.0
@export var min_pitch : float = 0.8
@export var max_pitch : float = 1.2
@export var play_on_ready : bool = false

var audio_players = []


func _ready():
	if get_child_count() == 0:
		print_debug("no children found")
		return
	
	audio_players = get_children()
	if volume_modifier == 0.0:
		return
	
	for audio_player in audio_players:
		var player = audio_player as AudioStreamPlayer2D
		player.volume_db += volume_modifier
	
	if not play_on_ready:
		return
	
	play_random_sound()


func play_random_sound():
	if audio_players.size() == 0:
		return
	
	var random_audio_player = audio_players.pick_random() as AudioStreamPlayer2D
	var random_pitch = randf_range(min_pitch, max_pitch)
	random_audio_player.pitch_scale = random_pitch
	random_audio_player.play()

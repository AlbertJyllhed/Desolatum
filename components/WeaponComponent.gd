extends Node2D
class_name WeaponComponent

@onready var audio_player_component : AudioPlayerComponent = $AudioPlayerComponent


func attack(attack_vector : Vector2):
	audio_player_component.play_random_sound()

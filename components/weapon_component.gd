extends Node2D
class_name WeaponComponent

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


func attack(_attack_vector : Vector2):
	audio_player.play()

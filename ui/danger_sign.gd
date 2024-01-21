extends Control

@export var signs : Array[Texture2D]

@onready var texture_rect : TextureRect = $TextureRect


func _ready():
	GameEvents.wave_updated.connect(on_wave_updated)


func on_wave_updated(index):
	texture_rect.texture = signs[index]

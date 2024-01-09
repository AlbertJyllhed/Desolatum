extends Control

@onready var progress_bar : TextureProgressBar = $TextureProgressBar
@onready var label : Label = $Label


func _ready():
	GameEvents.ammo_updated.connect(on_ammo_updated)


func on_ammo_updated(ammo : int, max_ammo : int):
	progress_bar.max_value = max_ammo
	progress_bar.value = ammo
	label.text = str(ammo) + " / " + str(max_ammo)

extends Control

@onready var gun_indicator : TextureRect = $NinePatchRect/VBoxContainer/GunIcon/Border
@onready var melee_indicator : TextureRect = $NinePatchRect/VBoxContainer/MeleeIcon/Border


func _ready():
	GameEvents.weapons_updated.connect(on_weapons_updated)


func on_weapons_updated(index : int):
	if index == 0:
		melee_indicator.hide()
		gun_indicator.show()
		return
	
	gun_indicator.hide()
	melee_indicator.show()

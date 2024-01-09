extends Control

@onready var energy_label : Label = $NinePatchRect/VBoxContainer/HBoxContainer/Label
@onready var ore_label : Label = $NinePatchRect/VBoxContainer/HBoxContainer2/Label


func _ready():
	GameEvents.energy_updated.connect(on_energy_updated)
	GameEvents.ore_updated.connect(on_ore_updated)


func on_energy_updated(energy):
	energy_label.text = str(energy)


func on_ore_updated(ore):
	ore_label.text = str(ore)

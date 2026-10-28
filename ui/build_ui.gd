@icon("res://addons/at-icons/control/hammer.svg")
extends Control

@onready var icon : TextureRect = $NinePatchRect/HBoxContainer/BuildingIcon3
@onready var label : Label = $Label


func _ready() -> void:
	hide()
	GameEvents.build_mode_changed.connect(func(active): visible = active)
	GameEvents.building_selected.connect(on_building_selected)


func on_building_selected(item: BuildingItem):
	icon.texture = item.icon
	label.text = "%s (%d ore)" % [item.name, item.ore_cost]

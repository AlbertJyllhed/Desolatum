extends Control
class_name UpgradeUI

@onready var icon : TextureRect = $HBoxContainer/Icon
@onready var label : Label = $HBoxContainer/Label


func setup(upgrade : UpgradeItem):
	icon.texture = upgrade.icon
	label.text = upgrade.name

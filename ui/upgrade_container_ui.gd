extends Control
class_name UpgradeContainerUI

@onready var upgrade_container : GridContainer = $NinePatchRect/VBoxContainer/GridContainer

var upgrade_ui_scene = preload("res://ui/upgrade_ui.tscn")


func _ready() -> void:
	GameEvents.add_upgrade.connect(on_add_upgrade)
	GameEvents.item_picked_up.connect(on_item_picked_up)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("show_upgrades"):
		show()
	
	if event.is_action_released("show_upgrades"):
		hide()


func on_add_upgrade(upgrade : UpgradeItem):
	var upgrade_ui_instance = upgrade_ui_scene.instantiate() as UpgradeUI
	upgrade_container.add_child(upgrade_ui_instance)
	upgrade_ui_instance.setup(upgrade)
	print("added %s to ui" % upgrade.name)


func on_item_picked_up(item : Item):
	if item is not UpgradeItem:
		return
	
	var upgrade = item as UpgradeItem
	on_add_upgrade(upgrade)

extends Menu
class_name UpgradeContainerUI

@onready var upgrade_container: GridContainer = $VBoxContainer/GridContainer

var upgrade_ui_scene = preload("uid://c0kmp3178vt22")
var upgrade_instances: Array[UpgradeUI] = []


func _ready() -> void:
	super._ready()
	GameEvents.add_upgrade.connect(on_add_upgrade)
	GameEvents.item_picked_up.connect(on_item_picked_up)
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("show_upgrades"):
		show()
	
	if event.is_action_released("show_upgrades"):
		hide()


func on_add_upgrade(upgrade: UpgradeItem) -> void:
	if not upgrade_instances.is_empty():
		for instance in upgrade_instances:
			if instance.has_upgrade(upgrade):
				instance.setup(upgrade, 1)
				return
	
	var upgrade_instance = upgrade_ui_scene.instantiate() as UpgradeUI
	upgrade_container.add_child(upgrade_instance)
	upgrade_instances.append(upgrade_instance)
	upgrade_instance.setup(upgrade)


func on_item_picked_up(item: Item) -> void:
	if item is UpgradeItem:
		var upgrade = item as UpgradeItem
		on_add_upgrade(upgrade)

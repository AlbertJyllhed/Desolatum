extends Node
class_name UpgradeHandlerComponent

@export var allowed_upgrades : Array[String]
@export var upgrade_node : Node2D

#var active_upgrades : Array[Upgrade]


func _ready():
	GameEvents.item_picked_up.connect(on_item_picked_up)


func on_item_picked_up(item : Item):
	if not item is UpgradeItem:
		return
	
	if not allowed_upgrades.has(item.id):
		return
	
	var upgrade_instance = item.upgrade_scene.instantiate() as Upgrade
	add_child(upgrade_instance)
	upgrade_instance.apply_upgrade(upgrade_node)
	upgrade_instance.id = item.id
	GameEvents.upgrade_added.emit(item, upgrade_instance)
	#active_upgrades.append(upgrade_instance)

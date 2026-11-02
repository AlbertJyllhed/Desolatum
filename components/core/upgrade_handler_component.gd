extends Node
class_name UpgradeHandlerComponent

@export var allowed_upgrades : Array[String]
@export var upgrade_node : Node2D


func _ready():
	GameEvents.add_upgrade.connect(on_add_upgrade)
	GameEvents.item_picked_up.connect(on_item_picked_up)


func on_add_upgrade(item : UpgradeItem):
	#called at level start when playerstats sends out current upgrades
	add_upgrade(item)


func on_item_picked_up(item : Item):
	#use when adding brand new upgrades
	if not item is UpgradeItem:
		return
	
	add_upgrade(item)


func add_upgrade(item : UpgradeItem):
	if not allowed_upgrades.has(item.id):
		return
	
	var upgrade_instance = item.upgrade_scene.instantiate() as Upgrade
	add_child(upgrade_instance)
	upgrade_instance.apply_upgrade(upgrade_node)
	upgrade_instance.id = item.id

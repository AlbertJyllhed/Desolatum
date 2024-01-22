extends Node
class_name UpgradeHandlerComponent

@export var allowed_upgrades : Array[String]

var base_node : Node2D
var active_upgrades : Array[Upgrade]


func _ready():
	GameEvents.item_picked_up.connect(on_item_picked_up)
	base_node = owner as Node2D


func on_item_picked_up(item : Item):
	if not item is UpgradeItem:
		return
	
	if not allowed_upgrades.has(item.id):
		return
	
	var upgrade_instance = item.upgrade_scene.instantiate() as Upgrade
	base_node.add_child(upgrade_instance)
	upgrade_instance.global_position = base_node.global_position
	active_upgrades.append(upgrade_instance)

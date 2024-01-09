extends Node

@export var upgrade_pool : Array[UpgradeItem]
@export var upgrade_selection_scene : PackedScene

var current_upgrades = {}


#func _ready():
#	GameEvents.level_up.connect(on_level_up)


func on_level_up(level : int):
	var chosen_upgrade = upgrade_pool.pick_random() as UpgradeItem
	if not chosen_upgrade:
		return
	
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	var upgrade_selection_instance = upgrade_selection_scene.instantiate()
	ui_layer.add_child(upgrade_selection_instance)
	ui_layer.move_child(upgrade_selection_instance, 0)
	upgrade_selection_instance.set_upgrades([chosen_upgrade] as Array[UpgradeItem])
	upgrade_selection_instance.upgrade_selected.connect(apply_upgrade)


func apply_upgrade(upgrade : UpgradeItem):
	var has_upgrade = current_upgrades.has(upgrade.id)
	if not has_upgrade:
		current_upgrades[upgrade.id] = {
			"resource" : upgrade,
			"quantity" : 1
		}
	else:
		current_upgrades[upgrade.id]["quantity"] += 1
	
	GameEvents.upgrade_added.emit(upgrade, current_upgrades)

extends Item
class_name EquipmentItem

enum EquipmentType {
	gun,
	melee,
	consumable
}

const GUN_SCENE := preload("res://components/weapons/player/gun.tscn")

@export var type = EquipmentType.gun
## Data-driven gun. When set (and equipment_scene is empty) the generic gun
## scene is used, so a new gun only needs a GunData resource.
@export var gun_data : GunData
## Custom scene for weapons that need their own setup (melee, consumables, ...)
@export var equipment_scene : PackedScene


func instantiate_equipment() -> Node:
	if equipment_scene:
		return equipment_scene.instantiate()

	if gun_data:
		var gun = GUN_SCENE.instantiate()
		gun.data = gun_data
		return gun

	push_error("EquipmentItem '%s' has neither equipment_scene nor gun_data" % id)
	return null

extends Item
class_name EquipmentItem

enum EquipmentType { 
	gun, 
	melee,
	ability,
	consumable
}

@export var type = EquipmentType.gun
@export var equipment_scene : PackedScene

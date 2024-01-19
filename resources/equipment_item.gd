extends Item
class_name EquipmentItem

enum EquipmentType { 
	gun, 
	melee,
	building,
	tool
}

@export var type = EquipmentType.gun
@export var equipment_scene : PackedScene

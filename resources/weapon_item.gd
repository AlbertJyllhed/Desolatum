extends Item
class_name WeaponItem

enum WeaponType { gun, melee }
@export var type = WeaponType.gun
@export var weapon_scene : PackedScene

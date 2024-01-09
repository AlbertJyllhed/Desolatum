extends Node2D
class_name EnemyWeaponBase

signal has_target
signal finished

@export var weapon_component : WeaponComponent

@onready var attack_area : TargetLocatorArea = $AttackArea
@onready var target_locator_ray : TargetLocatorRay = $TargetLocatorRay

var attack_vector : Vector2


func attack():
	if not weapon_component:
		print("Error: no weapon component attached!")
		return
	
	var player = target_locator_ray.player_node
	if not is_instance_valid(player):
		return
	
	attack_vector = player.global_position
	#look_at(attack_vector)
	weapon_component.attack(attack_vector)


func _on_attack_area_body_entered(body):
	attack_area.deactivate_detection()
	if not target_locator_ray.has_target():
		return
	
	has_target.emit()

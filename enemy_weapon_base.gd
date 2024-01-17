extends Node2D
class_name EnemyWeaponBase

signal has_target
signal finished

@export var weapon_component : WeaponComponent

@onready var attack_area : TargetLocatorArea = $AttackArea
@onready var target_locator_ray : TargetLocatorRay = $TargetLocatorRay
@onready var animation_player : AnimationPlayer = $AnimationPlayer

var attack_vector : Vector2


func _ready():
	var player = get_tree().get_first_node_in_group("player")
	target_locator_ray.set_target(player)


func attack():
	if not weapon_component:
		print("Error: no weapon component attached!")
		return
	
	var player = target_locator_ray.target
	if not is_instance_valid(player):
		return
	
	animation_player.play("attack")
	attack_vector = player.global_position
	
	if attack_vector.x > global_position.x:
		weapon_component.scale.y = 1
	else:
		weapon_component.scale.y = -1
	
	weapon_component.look_at(attack_vector)
	weapon_component.attack(attack_vector)


func _on_attack_area_body_entered(body):
	attack_area.deactivate_detection()
	if not target_locator_ray.has_target():
		return
	
	has_target.emit()

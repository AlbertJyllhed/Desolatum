extends Node2D
class_name EnemyWeaponBase

signal has_target

@export var weapon_component: WeaponComponent

@onready var pivot: Node2D = $Pivot
@onready var attack_area: TargetLocatorArea = $AttackArea
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _player: Player
var _target_locator_ray: TargetLocatorRay
var building_target: Building


func setup_weapon(player: Player, target_locator_ray: TargetLocatorRay) -> void:
	_player = player
	_target_locator_ray = target_locator_ray
	if is_instance_valid(player):
		target_locator_ray.set_target(player)


func attack(attack_vector : Vector2):
	if not weapon_component:
		push_error("Error: no weapon component attached!")
		return
	
	animation_player.play("attack")
	
	if attack_vector.x > global_position.x:
		pivot.scale.y = 1
	else:
		pivot.scale.y = -1
	
	pivot.look_at(attack_vector)
	weapon_component.attack(attack_vector)


func _on_attack_area_body_entered(body):
	if body is Building:
		return # Hunt decides when a building is worth attacking
	
	building_target = null # the player takes priority
	attack_area.deactivate_detection()
	if not _target_locator_ray.has_target():
		return
	
	has_target.emit()

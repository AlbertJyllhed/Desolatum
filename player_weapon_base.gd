extends Node2D
class_name PlayerWeaponBase

@export var firing_component : FiringComponent
@export var weapon_component : WeaponComponent
@export var ammo_component : AmmoComponent

@export_group("Camera Effects")
@export var recoil : float = 0.1
@export var power : float = 2.0

@onready var pivot : Node2D = $Pivot
@onready var sprite : Sprite2D = $Pivot/WeaponSprite
@onready var animation_player = $AnimationPlayer

var camera : PlayerCamera
var attack_vector : Vector2
var disabled : bool = false


func _ready():
	if not firing_component:
		return
	
	firing_component.fire_weapon.connect(try_attack)
	camera = get_viewport().get_camera_2d() as PlayerCamera
	
	if not ammo_component:
		return
	
	ammo_component.has_ammo.connect(attack)
	ammo_component.reloading.connect(reload)


func _physics_process(_delta):
	attack_vector = get_global_mouse_position()
	if GamepadManager.using_gamepad:
		attack_vector = pivot.global_position + GamepadManager.get_aim_direction()
	
	pivot.look_at(attack_vector)
	
	if attack_vector.x > global_position.x:
		pivot.scale.y = 1
	else:
		pivot.scale.y = -1
	
	if attack_vector.y > global_position.y:
		sprite.z_index = 0
	else:
		sprite.z_index = -1


func try_attack():
	if disabled:
		return
	
	if ammo_component:
		ammo_component.use_ammo()
		return
	
	attack()


func attack():
	if not weapon_component:
		print("Error: no weapon component found!")
		return
	
	weapon_component.attack(attack_vector)
	if animation_player.is_playing():
		animation_player.stop()
	
	animation_player.play("attack")
	var direction = (attack_vector - global_position).normalized() * 100
	camera.shake(-direction, recoil, power)


func reload(time : float):
	animation_player.play("reload", -1, time)


func disable(value : bool):
	disabled = value
	firing_component.disabled = value
	if ammo_component:
		ammo_component.disable(value)
	
	visible = !value

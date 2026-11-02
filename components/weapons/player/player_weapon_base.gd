@icon("res://addons/at-icons/node2d/gun.svg")
extends Node2D
class_name PlayerWeaponBase

@export var firing_component: FiringComponent
@export var weapon_component: WeaponComponent
@export var ammo_component: AmmoComponent

@export_group("Camera Effects")
@export var recoil: float = 0.1
@export var power: float = 2.0

@export_group("Config")
## Locks the weapon pivot when attacking,
## the player cannot rotate their weapon during the animation
@export var lock_pivot_on_attack: bool = false

@onready var pivot: Node2D = $Pivot
@onready var sprite: Sprite2D = $Pivot/WeaponSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var camera: PlayerCamera
var attack_vector: Vector2
var attacking: bool = false
var disabled: bool = false


func _ready():
	if not firing_component:
		return
	
	GameEvents.stats_changed.connect(_on_stats_changed)
	firing_component.fire_weapon.connect(try_attack)
	camera = get_viewport().get_camera_2d() as PlayerCamera
	
	if ammo_component:
		ammo_component.has_ammo.connect(attack)
		ammo_component.reloading.connect(reload)


func _physics_process(_delta):
	attack_vector = get_aim_direction()
	pivot.look_at(attack_vector)
	
	if attack_vector.x > global_position.x:
		pivot.scale.y = 1
	else:
		pivot.scale.y = -1
	
	if attack_vector.y > pivot.global_position.y:
		sprite.z_index = 0
	else:
		sprite.z_index = -1
	
	if disabled:
		return
	
	if firing_component:
		firing_component.process_trigger(
			Input.is_action_just_pressed("attack"),
			Input.is_action_pressed("attack"))
	
	if ammo_component and Input.is_action_just_pressed("reload"):
		ammo_component.reload()


func get_aim_direction() -> Vector2:
	if GamepadManager.using_gamepad:
		return pivot.global_position + GamepadManager.get_aim_direction()
	else:
		return get_global_mouse_position()


func try_attack():
	if disabled:
		return
	
	if ammo_component:
		ammo_component.use_ammo()
		return
	
	attack()


func attack():
	if not weapon_component:
		push_error("Error: no weapon component found!")
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
		ammo_component.set_active(not value)
	visible = !value


func _on_stats_changed(mods: Dictionary) -> void:
	for c in [firing_component, ammo_component, weapon_component]:
		if c and c.has_method("apply_stats"):
			c.apply_stats(mods)

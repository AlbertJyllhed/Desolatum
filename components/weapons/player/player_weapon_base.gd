@icon("res://addons/at-icons/node2d/gun.svg")
extends Node2D
class_name PlayerWeaponBase

## Emitted on every attack. The inventory forwards it to the player to slow them down
signal attacked(move_speed_multiplier: float, slow_duration: float)

@export var firing_component: FiringComponent
@export var weapon_component: WeaponComponent
@export var ammo_component: AmmoComponent

@export_group("Camera Effects")
## Camera kick in pixels, opposite the attack direction. Eases back by itself.
@export var recoil: float = 1.0
## Extra camera shake added per attack (0 to 1). 0 = kick only.
@export var power: float = 0.0

@export_group("Movement")
## Player move speed is multiplied by this after each attack. 1 = no slowdown
@export_range(0, 1, 0.05) var attack_move_speed_multiplier: float = 1.0
## Seconds the slowdown lasts after each attack
@export_range(0, 2, 0.05, "or_greater") var attack_slow_duration: float = 0.3

@export_group("Turning")
## Slows how fast the weapon can turn toward the aim while attack is held
@export var limit_turn_while_firing: bool = false
## Degrees per second the weapon can turn while attack is held. 0 = locked
@export_range(0, 1080, 1, "or_greater") var firing_turn_speed: float = 90.0

@onready var pivot: Node2D = $Pivot
@onready var sprite: Sprite2D = $Pivot/WeaponSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var camera: PlayerCamera
## Point the weapon is actually aiming at (lags behind the cursor when turning is limited)
var attack_vector: Vector2
## Current weapon angle in radians, global
var aim_angle: float = 0.0
var attacking: bool = false
var disabled: bool = false


func _ready():
	if not firing_component:
		return
	
	GameEvents.stats_changed.connect(_on_stats_changed)
	firing_component.fire_weapon.connect(try_attack)
	camera = get_viewport().get_camera_2d() as PlayerCamera
	if weapon_component is GunComponent:
		weapon_component.aim_source = self
	
	if ammo_component:
		ammo_component.has_ammo.connect(attack)
		ammo_component.reloading.connect(reload)


func _physics_process(delta: float) -> void:
	update_aim(delta)
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


## Turns aim_angle toward the cursor (instantly, or limited while firing)
## and places attack_vector along it, so shots go where the weapon points.
func update_aim(delta: float) -> void:
	var target: Vector2 = get_aim_direction()
	var target_angle: float = (target - pivot.global_position).angle()

	if limit_turn_while_firing and not disabled and Input.is_action_pressed("attack"):
		aim_angle = rotate_toward(aim_angle, target_angle, deg_to_rad(firing_turn_speed) * delta)
	else:
		aim_angle = target_angle

	# keep the cursor's distance so anything using the point (e.g. recoil) behaves as before
	var distance: float = maxf(pivot.global_position.distance_to(target), 32.0)
	attack_vector = pivot.global_position + Vector2.from_angle(aim_angle) * distance


func snap_aim() -> void:
	aim_angle = (get_aim_direction() - pivot.global_position).angle()


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
	attacked.emit(attack_move_speed_multiplier, attack_slow_duration)
	if animation_player.is_playing():
		animation_player.stop()
	
	animation_player.play("attack")
	if camera:
		var direction : Vector2 = (attack_vector - global_position).normalized()
		camera.kick(-direction, recoil)
		if power > 0.0:
			camera.add_shake(power)


func reload(time : float):
	animation_player.play("reload", -1, time)


func disable(value : bool):
	disabled = value
	firing_component.disabled = value
	if ammo_component:
		ammo_component.set_active(not value)
	visible = !value
	if not value:
		snap_aim() # don't swing in from wherever it was holstered


func _on_stats_changed(mods: Dictionary) -> void:
	for c in [firing_component, ammo_component, weapon_component]:
		if c and c.has_method("apply_stats"):
			c.apply_stats(mods)

extends PlayerWeaponBase
class_name Gun

## Generic data-driven gun. Builds its firing and ammo components from a
## GunData resource, so adding a gun only needs a new GunData .tres.

const FIRING_SCENES := {
	GunData.FireMode.SINGLE: preload("uid://b63err5lwk6fn"),
	GunData.FireMode.AUTO: preload("uid://w4snfyux8ecm"),
	GunData.FireMode.BURST: preload("uid://dcrdtvgh6el3y"),
}
const AMMO_SCENES := {
	GunData.AmmoMode.MAGAZINE: preload("uid://d3vb0c3uyj7qk"),
	GunData.AmmoMode.RECHARGE: preload("uid://d2bqfjunuovrn"),
}

@export var data : GunData

@onready var gun_component : GunComponent = $Pivot/GunComponent
@onready var reload_progress_bar = $ReloadProgressBar


func _ready():
	if not data:
		push_error("Gun '%s' has no GunData assigned" % name)
		return
	
	_build()
	super._ready()


func _build() -> void:
	
	var firing = FIRING_SCENES[data.fire_mode].instantiate()
	firing.base_cooldown = data.cooldown
	if data.fire_mode == GunData.FireMode.BURST:
		firing.max_bursts = data.burst_count
		firing.burst_interval = data.burst_interval
	add_child(firing)
	firing_component = firing
	
	if data.ammo_mode != GunData.AmmoMode.NONE:
		var ammo: AmmoComponent = AMMO_SCENES[data.ammo_mode].instantiate()
		ammo.base_ammo = data.ammo
		ammo.base_reload_time = data.reload_time
		ammo.reload_while_holstered = data.reload_while_holstered
		add_child(ammo)
		ammo_component = ammo
		reload_progress_bar.bind(ammo)

	gun_component.configure(data)
	weapon_component = gun_component

	if data.attack_animation:
		_use_attack_animation(data.attack_animation)
	
	if data.texture:
		sprite.texture = data.texture
		sprite.hframes = 1
		sprite.vframes = 1
	sprite.frame = data.sprite_frame
	
	recoil = data.recoil
	power = data.shake_power
	limit_turn_while_firing = data.limit_turn_while_firing
	firing_turn_speed = data.firing_turn_speed
	attack_move_speed_multiplier = data.attack_move_speed_multiplier
	attack_slow_duration = data.attack_slow_duration


## Swaps the "attack" animation for this gun only. The library comes from the
## base scene and is shared by every gun, so it's duplicated before changing it.
func _use_attack_animation(animation: Animation) -> void:
	var library: AnimationLibrary = animation_player.get_animation_library(&"").duplicate()
	library.remove_animation(&"attack")
	library.add_animation(&"attack", animation)
	animation_player.remove_animation_library(&"")
	animation_player.add_animation_library(&"", library)

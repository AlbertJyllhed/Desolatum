extends WeaponComponent
class_name GunComponent

signal shot_projectile(new_projectile)

@export var bullet_scene : PackedScene

@export var base_bullet_spread : float = 0.1
var bullet_spread : float = 0.1

@export var base_bullet_speed : float = 400.0
var bullet_speed : float = 400.0

@export var base_damage : int = 1
var damage : int = 1

@export var base_crit_chance : float = 0.0
var crit_chance : float = 0.0

@export var base_bullet_explode_chance : float = 0.0
var bullet_explode_chance : float = 0.0

@export var projectiles : Array[float] = [0]

## Passed on to projectiles so steering behaviours can follow the shooter's aim
var aim_source : Node2D

var foreground_layer : Node2D


func _ready():
	foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
	reset_stats()


## Copies the base values into the live stats (before any upgrades apply)
func reset_stats() -> void:
	bullet_spread = base_bullet_spread
	bullet_speed = base_bullet_speed
	damage = base_damage
	crit_chance = base_crit_chance
	bullet_explode_chance = base_bullet_explode_chance


func configure(data : GunData) -> void:
	bullet_scene = data.projectile
	base_bullet_spread = data.spread
	base_bullet_speed = data.speed
	base_damage = data.damage
	base_crit_chance = data.crit_chance
	base_bullet_explode_chance = data.explode_chance
	projectiles = data.pattern.duplicate()
	position = Vector2(data.muzzle_offset, 0)

	if data.sounds.size() > 0:
		var randomizer := AudioStreamRandomizer.new()
		randomizer.random_pitch = 1.0594631
		for sound in data.sounds:
			randomizer.add_stream(-1, sound)
		audio_player.stream = randomizer

	reset_stats()


func attack(attack_vector : Vector2):
	super.attack(attack_vector)

	if not bullet_scene:
		push_error("GunComponent '%s' has no bullet scene" % name)
		return

	var dir := (attack_vector - global_position).normalized()
	for angle_offset in projectiles:
		var spread := randf_range(-bullet_spread, bullet_spread)
		var shot := ShotInfo.new()
		shot.direction = dir.rotated(deg_to_rad(angle_offset) + spread)
		shot.speed = bullet_speed
		shot.is_crit = randf() < crit_chance
		shot.damage = damage * (3 if shot.is_crit else 1)
		shot.explode_chance = bullet_explode_chance
		shot.aim_source = aim_source

		var bullet_instance = bullet_scene.instantiate()
		foreground_layer.add_child(bullet_instance)
		bullet_instance.global_position = global_position
		bullet_instance.setup(shot)
		shot_projectile.emit(bullet_instance)


func apply_stats(mods: Dictionary) -> void:
	damage = max(mods["damage"].get_values(base_damage), 1)
	bullet_speed = clamp(mods["bullet_speed"].get_values(base_bullet_speed), 50, 1000)
	bullet_spread = clamp(mods["bullet_spread"].get_values(base_bullet_spread), 0, 1.0)
	crit_chance = clamp(mods["crit_chance"].get_values(base_crit_chance), 0, 0.8)
	bullet_explode_chance = clamp(mods["explode_chance"].get_values(base_bullet_explode_chance), 0, 1)

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

## When off (e.g. melee slashes) only damage and crit upgrades apply;
## bullet speed, spread and explode chance stay at their base values
@export var use_projectile_upgrades : bool = true

@export_group("Shot Pattern")
## Projectiles fired per shot
@export_range(1, 32, 1, "or_greater") var projectile_count : int = 1
## Total angle in degrees the projectiles fan out over, evenly spaced
@export_range(0, 360, 1) var fan_angle : float = 0.0
## Side-by-side distance in pixels between neighbouring projectiles
@export var projectile_spacing : float = 0.0

@export_group("Casings")
## Casing ejected on each shot (a ShellCasing scene). Leave empty for none
@export var casing_scene : PackedScene
## How far above the shooter's feet casings start, in pixels
@export var casing_height : float = 6.0

## Passed on to projectiles so steering behaviours can follow the shooter's aim
var aim_source : Node2D

var foreground_layer : Node2D
var base_layer : Node2D


func _ready():
	foreground_layer = get_tree().get_first_node_in_group("foreground_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")
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
	use_projectile_upgrades = data.use_projectile_upgrades
	projectile_count = data.projectile_count
	fan_angle = data.fan_angle
	projectile_spacing = data.projectile_spacing
	position = Vector2(data.muzzle_offset, 0)
	casing_scene = data.casing_scene

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

	var dir : Vector2 = (attack_vector - global_position).normalized()
	# same rotational side as the fan, so angled projectiles don't cross paths
	var side : Vector2 = dir.rotated(PI / 2.0)
	for i in projectile_count:
		# -0.5 .. 0.5 across the pattern, 0 for a single projectile
		var t : float = 0.0
		if projectile_count > 1:
			t = float(i) / float(projectile_count - 1) - 0.5

		var spread : float = randf_range(-bullet_spread, bullet_spread)
		var shot := ShotInfo.new()
		shot.direction = dir.rotated(deg_to_rad(fan_angle * t) + spread)
		shot.speed = bullet_speed
		shot.is_crit = randf() < crit_chance
		shot.damage = damage * (3 if shot.is_crit else 1)
		shot.explode_chance = bullet_explode_chance
		shot.aim_source = aim_source

		var spacing_offset : float = projectile_spacing * t * float(projectile_count - 1)
		var bullet_instance : Node2D = bullet_scene.instantiate()
		foreground_layer.add_child(bullet_instance)
		bullet_instance.global_position = global_position + side * spacing_offset
		bullet_instance.setup(shot)
		shot_projectile.emit(bullet_instance)

	eject_casing(dir)


## Throws a casing out of the gun, backwards and to the upper side of the aim.
func eject_casing(dir : Vector2) -> void:
	if not casing_scene or not base_layer:
		return
	var side : Vector2 = dir.orthogonal()
	if side.y > 0.0:
		side = -side
	# Out of the gun body (the pivot), not the muzzle.
	var origin : Vector2 = (get_parent() as Node2D).global_position if get_parent() is Node2D else global_position
	var casing := Pool.spawn(casing_scene, base_layer, origin, dir.angle()) as ShellCasing
	if casing:
		casing.launch(side - dir * 0.5, casing_height)


func apply_stats(mods: Dictionary) -> void:
	damage = max(mods["damage"].get_values(base_damage), 1)
	crit_chance = clamp(mods["crit_chance"].get_values(base_crit_chance), 0, 0.8)
	if not use_projectile_upgrades:
		return

	bullet_speed = clamp(mods["bullet_speed"].get_values(base_bullet_speed), 50, 1000)
	bullet_spread = clamp(mods["bullet_spread"].get_values(base_bullet_spread), 0, 1.0)
	bullet_explode_chance = clamp(mods["explode_chance"].get_values(base_bullet_explode_chance), 0, 1)

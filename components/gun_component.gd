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

var foreground_layer : Node2D


func _ready():
	shot_projectile.connect(crit)
	foreground_layer = get_tree().get_first_node_in_group("foreground_layer")


func attack(attack_vector : Vector2):
	super.attack(attack_vector)
	
	for i in projectiles.size():
		var bullet_instance = bullet_scene.instantiate()
		foreground_layer.add_child(bullet_instance)
		bullet_instance.global_position = global_position
		var dir := (attack_vector - global_position).normalized()
		var spread := randf_range(-bullet_spread, bullet_spread)
		var angle := dir.rotated(deg_to_rad(projectiles[i]) + spread)
		bullet_instance.setup(angle, bullet_speed, damage)
		shot_projectile.emit(bullet_instance)


func crit(bullet_instance):
	bullet_instance.explode_chance = bullet_explode_chance
	if randf() > crit_chance:
		return
	
	bullet_instance.hitbox.damage *= 3


func apply_stats(mods: Dictionary) -> void:
	damage = max(mods["damage"].get_values(base_damage), 1)
	bullet_speed = clamp(mods["bullet_speed"].get_values(base_bullet_speed), 50, 1000)
	bullet_spread = clamp(mods["bullet_spread"].get_values(base_bullet_spread), 0, 1.0)
	crit_chance = clamp(mods["crit_chance"].get_values(base_crit_chance), 0, 0.8)
	bullet_explode_chance = clamp(mods["explode_chance"].get_values(base_bullet_explode_chance), 0, 1)

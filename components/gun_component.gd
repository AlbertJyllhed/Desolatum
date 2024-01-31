extends WeaponComponent
class_name GunComponent

signal shot_projectile(new_projectile)

@export var projectile : PackedScene

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
	GameEvents.stats_changed.connect(on_stats_changed)
	shot_projectile.connect(crit)
	foreground_layer = get_tree().get_first_node_in_group("foreground_layer")


func attack(attack_vector : Vector2):
	super.attack(attack_vector)
	
	for i in projectiles.size():
		var new_projectile = projectile.instantiate()
		foreground_layer.add_child(new_projectile)
		new_projectile.global_position = global_position
		var direction = (attack_vector - global_position).normalized()
		var radians = deg_to_rad(projectiles[i])
		var angle = direction.rotated(radians)
		var deviation = randf_range(-bullet_spread, bullet_spread)
		var deviation_vector = Vector2(deviation, deviation)
		new_projectile.setup(angle + deviation_vector, bullet_speed, damage)
		shot_projectile.emit(new_projectile)


func crit(new_projectile):
	new_projectile.explode_chance = bullet_explode_chance
	if randf() > crit_chance:
		return
	
	new_projectile.hitbox.damage *= 3


func on_stats_changed(mods : Dictionary):
	damage = max(mods["damage"].get_values(base_damage), 1)
	bullet_speed = clamp(mods["bullet_speed"].get_values(base_bullet_speed), 50, 1000)
	bullet_spread = clamp(mods["bullet_spread"].get_values(base_bullet_spread), 0, 1.0)
	crit_chance = clamp(mods["crit_chance"].get_values(base_crit_chance), 0, 0.8)
	bullet_explode_chance = clamp(mods["explode_chance"].get_values(base_bullet_explode_chance), 0, 1)
	
	#print("damage: " + str(damage))
	#print("deviation: " + str(bullet_spread))
	#print("crit_chance: " + str(crit_chance))

extends WeaponComponent
class_name GunComponent

signal shot_projectile(new_projectile)

@export var projectile : PackedScene

@export var base_projectile_deviation : float = 0.1
var projectile_deviation : float = 0.1

@export var base_projectile_speed : float = 400.0
var projectile_speed : float = 400.0

@export var base_projectile_damage : int = 1
var projectile_damage : int = 1

@export var projectiles : Array[float] = [0]

var foreground_layer : Node2D


func _ready():
	projectile_deviation = base_projectile_deviation
	projectile_speed = base_projectile_speed
	projectile_damage = base_projectile_damage
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
		var deviation = randf_range(-projectile_deviation, projectile_deviation)
		var deviation_vector = Vector2(deviation, deviation)
		new_projectile.setup(angle + deviation_vector, projectile_speed, projectile_damage)
		shot_projectile.emit(new_projectile)

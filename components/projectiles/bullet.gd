@icon("res://addons/at-icons/node2d/bullet.svg")
extends CharacterBody2D
class_name Projectile

signal wall_hit

@export var impact_scene : PackedScene

@export_group("Stats")
@export var speed : float = 400
@export_range(0, 1, 0.1) var bounce_chance : float = 0
@export_range(0, 1, 0.1) var pierce_chance : float = 0
@export_range(0, 1, 0.1) var explode_chance : float = 0

@onready var sprite : Sprite2D = $Sprite2D
@onready var hitbox : Hitbox = $Hitbox

var base_layer : Node2D
var direction = Vector2.ZERO
## Node with get_aim_direction(), used by steering behaviours. May be null.
var aim_source : Node2D


func setup(shot : ShotInfo):
	direction = shot.direction
	speed = shot.speed
	hitbox.damage = shot.damage
	# the scene's own explode_chance is inherent to the projectile,
	# the shooter's (upgrades, launchers) stacks on top of it
	explode_chance = clamp(explode_chance + shot.explode_chance, 0, 1)
	aim_source = shot.aim_source
	sprite.rotation = direction.angle()
	base_layer = get_tree().get_first_node_in_group("base_layer")


func explode():
	if explode_chance > randf():
		var explosion_instance = Scenes.EXPLOSION.instantiate() as Node2D
		base_layer.call_deferred("add_child", explosion_instance)
		explosion_instance.global_position = global_position
	
	queue_free()


func _physics_process(delta):
	var collision_result = move_and_collide(direction * speed * delta)
	if not collision_result:
		return
	
	hit_wall(collision_result)
	
	if bounce_chance > randf():
		direction = direction.bounce(collision_result.get_normal())
		sprite.rotation = direction.angle()
		bounce_chance = max(bounce_chance * 0.9, 0)
		return
	
	explode()


func hit_wall(collision_result):
	wall_hit.emit()
	Pool.spawn(impact_scene, base_layer, collision_result.get_position(), collision_result.get_normal().angle())


func _on_hitbox_area_entered(_area):
	hitbox.knockback_vector = direction
	if pierce_chance > randf():
		pierce_chance = max(pierce_chance * 0.9, 0)
		return
	
	explode()

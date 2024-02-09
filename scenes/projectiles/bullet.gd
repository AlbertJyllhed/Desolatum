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

var explosion_scene : PackedScene = preload("res://particles/explosion.tscn")
var base_layer : Node2D
var direction = Vector2.ZERO


func setup(new_direction, new_speed = 400, new_damage = 1):
	direction = new_direction
	speed = new_speed
	hitbox.damage = new_damage
	sprite.rotation = direction.angle()
	base_layer = get_tree().get_first_node_in_group("base_layer")


func explode():
	if explosion_scene and explode_chance > randf():
		var explosion_instance = explosion_scene.instantiate() as Node2D
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
	var impact_instance = impact_scene.instantiate() as Node2D
	base_layer.add_child(impact_instance)
	impact_instance.global_position = collision_result.get_position()
	impact_instance.rotation = collision_result.get_normal().angle()


func _on_hitbox_area_entered(_area):
	hitbox.knockback_vector = direction
	if pierce_chance > randf():
		pierce_chance = max(pierce_chance * 0.9, 0)
		return
	
	explode()

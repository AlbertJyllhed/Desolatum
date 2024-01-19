extends CharacterBody2D

@export var speed = 400
@export var gravity = 500
@export var vertical_velocity : float = -100.0
@export var bounces : int = 0
@export var scene : PackedScene

@onready var sprite : Sprite2D = $Sprite2D
@onready var shadow_sprite : Sprite2D = $Shadow

var direction = Vector2.ZERO
var grounded : bool = false


func setup(new_direction : Vector2, new_speed : float, new_bounces : int):
	direction = new_direction
	speed = new_speed
	bounces = new_bounces


func check_ground_hit():
	if sprite.global_position.y > global_position.y and not grounded:
		sprite.global_position = global_position
		grounded = true
		create_instance()


func create_instance():
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	var instance = scene.instantiate() as Node2D
	base_layer.add_child(instance)
	instance.global_position = global_position
	queue_free()


func _physics_process(delta):
	if grounded:
		return
	
	check_ground_hit()
	
	vertical_velocity += gravity * delta
	sprite.global_position += Vector2(0, vertical_velocity) * delta
	
	var collision_result = move_and_collide(direction * speed * delta)
	if collision_result:
		direction = direction.bounce(collision_result.get_normal()) / 2
		rotation = direction.angle()

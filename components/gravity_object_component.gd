extends CharacterBody2D

signal ground_hit

@export var speed = 400
@export var gravity = 500
@export var vertical_velocity : float = -100.0

@onready var sprite : Sprite2D = $Sprite2D
@onready var shadow_sprite : Sprite2D = $Shadow

var direction = Vector2.ZERO
var grounded : bool = false


func check_ground_hit():
	if sprite.global_position.y > global_position.y and not grounded:
		sprite.global_position = global_position
		grounded = true
		ground_hit.emit()


func _physics_process(delta):
	check_ground_hit()
	
	if grounded:
		return
	
	vertical_velocity += gravity * delta
	sprite.global_position += Vector2(0, vertical_velocity) * delta
	
	var collision_result = move_and_collide(direction * speed * delta)
	if collision_result:
		direction = direction.bounce(collision_result.get_normal()) / 2
		rotation = direction.angle()

extends CharacterBody2D
class_name Entity

@export var base_speed : int = 40
var max_speed : int = 40

@export var acceleration : float = 500


func _ready():
	max_speed = base_speed


func _physics_process(delta):
	accelerate_in_direction(Vector2.ZERO, 0, 1000)
	move(delta)


func accelerate_in_direction(direction : Vector2, speed = max_speed, acc_speed = acceleration):
	var desired_velocity = direction * speed
	velocity = velocity.move_toward(desired_velocity, acc_speed * get_physics_process_delta_time())


func move_in_direction(direction : Vector2, speed = max_speed):
	velocity = direction * speed


func move(delta : float):
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal()) / 2

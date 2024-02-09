extends Entity
class_name EnemyEntity

@onready var health_component : HealthComponent = $HealthComponent
@onready var sprite : Sprite2D = $Sprite2D
@onready var hurtbox : Hurtbox = $Hurtbox
@onready var disable_timer : Timer = $DisableTimer

var direction : Vector2
var disabled : bool = false
var aggressive : bool = false


func _ready():
	super._ready()
	add_to_group("enemies")
	health_component.died.connect(on_died)
	hurtbox.hit.connect(knockback)
	disable_timer.timeout.connect(enable_movement)


func _physics_process(delta):
	if disabled:
		accelerate_in_direction(Vector2.ZERO, 0, 1000)
	else:
		flip_sprite(direction)
		accelerate_in_direction(direction)
	
	move(delta)


func flip_sprite(dir : Vector2):
	if dir.x < 0:
		sprite.flip_h = true
	elif dir.x > 0:
		sprite.flip_h = false


func knockback(knockback_direction : Vector2, disable_time : float):
	disabled = true
	move_in_direction(knockback_direction, 160)
	disable_timer.start(disable_time)


func enable_movement():
	disabled = false


func move(delta : float):
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		direction = velocity.normalized()


func on_died():
	remove_from_group("enemies")
	var camera = get_viewport().get_camera_2d() as PlayerCamera
	camera.random_shake(4, 4)

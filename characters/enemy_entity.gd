extends Entity
class_name EnemyEntity

@onready var health_component : HealthComponent = $HealthComponent
@onready var sprite : Sprite2D = $Sprite2D
@onready var disable_timer : Timer = $DisableTimer

var direction : Vector2
var disabled : bool = false
var aggressive : bool = false


func _ready():
	add_to_group("enemies")
	health_component.died.connect(on_died)
	disable_timer.timeout.connect(enable_movement)


func _physics_process(delta):
	if disabled:
		accelerate_in_direction(Vector2.ZERO, 0, 1000)
		move(delta)
		return
	
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false
		
	accelerate_in_direction(direction)
	move(delta)


func knockback(knockback_direction : Vector2):
	disabled = true
	move_in_direction(knockback_direction, 160)
	disable_timer.start()


func enable_movement():
	disabled = false


func move(delta : float):
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
		direction = velocity.normalized()


func on_died():
	remove_from_group("enemies")

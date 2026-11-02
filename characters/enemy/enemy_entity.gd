extends Entity
class_name EnemyEntity

@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var disable_timer: Timer = $DisableTimer

var direction: Vector2
var disabled: bool = false
var aggressive: bool = false
var blocker: Building
var blocker_time: int = 0

const BLOCKER_MEMORY_MSEC := 400

static var all_enemies: Array[EnemyEntity] = []


func _ready():
	super._ready()
	all_enemies.append(self)
	add_to_group("enemies")
	health_component.died.connect(on_died)
	hurtbox.hit.connect(knockback)
	disable_timer.timeout.connect(enable_movement)
	collision_mask |= 1 << 14


func _physics_process(delta):
	if disabled:
		accelerate_in_direction(Vector2.ZERO, 0, 1000)
	else:
		flip_sprite(direction)
		accelerate_in_direction(direction)
	
	move(delta)


## Makes sure the enemy is facing the direction of movement
func flip_sprite(dir : Vector2) -> void:
	sprite.flip_h = true if dir.x < 0 else false


func knockback(knockback_direction: Vector2, disable_time: float):
	disabled = true
	move_in_direction(knockback_direction, 160)
	disable_timer.start(disable_time)


func enable_movement():
	disabled = false


func move(delta : float):
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if collider is Building:
			blocker = collider
			blocker_time = Time.get_ticks_msec()
		velocity = velocity.bounce(collision.get_normal())
		direction = velocity.normalized()


func get_blocking_building() -> Building:
	if is_instance_valid(blocker) and Time.get_ticks_msec() - blocker_time < BLOCKER_MEMORY_MSEC:
		return blocker
	return null


func _exit_tree() -> void:
	all_enemies.erase(self)


func on_died():
	all_enemies.erase(self)
	remove_from_group("enemies")
	var camera = get_viewport().get_camera_2d() as PlayerCamera
	if camera:
		camera.random_shake(4, 4)

extends Node2D
class_name GasVent

@export var idle_time: float = 4.0
@export var warning_time: float = 1.0
@export var active_time: float = 2.5

@onready var hitbox: Hitbox = $Hitbox
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var timer: Timer = $Timer

enum State { IDLE, WARNING, ACTIVE }
var state := State.IDLE


func _ready() -> void:
	hitbox.collision_shape.disabled = true
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	# Randomize so vents on a level don't all pulse in sync
	timer.start(randf_range(0.0, idle_time))


func _on_timer_timeout():
	match state:
		State.IDLE:
			state = State.WARNING
			particles.amount_ratio = 0.2
			particles.emitting = true
			timer.start(warning_time)
		State.WARNING:
			state = State.ACTIVE
			particles.amount_ratio = 1.0
			hitbox.collision_shape.set_deferred("disabled", false)
			timer.start(active_time)
		State.ACTIVE:
			state = State.IDLE
			particles.emitting = false
			hitbox.collision_shape.set_deferred("disabled", true)
			timer.start(idle_time)

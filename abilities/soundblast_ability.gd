extends Node2D

@export var blast_texture : Texture2D
@export var duration : float = 6.0
@export var recharge_time : float = 20.0

@onready var sprite : Sprite2D = $Sprite2D
@onready var collision_shape : CollisionShape2D = $Hitbox/CollisionShape2D
@onready var active_timer : Timer = $ActiveTimer
@onready var cooldown_timer : Timer = $CooldownTimer

var charged : bool = true


func _physics_process(delta):
	if Input.is_action_just_pressed("alt_attack"):
		if not charged:
			return
		
		#activate ability
		collision_shape.disabled = false
		sprite.texture = blast_texture
		active_timer.start(duration)
		charged = false


func is_active():
	return false


func _on_cooldown_timer_timeout():
	charged = true


func _on_active_timer_timeout():
	collision_shape.disabled = true
	sprite.texture = null
	cooldown_timer.start(recharge_time)

extends Node
class_name FiringComponent

signal fire_weapon

@export_range(0, 6) var cooldown : float = 1.0

@onready var cooldown_timer : Timer = $CooldownTimer

var ready_to_shoot : bool = true
var disabled : bool = false


func _physics_process(_delta):
	if Input.is_action_just_pressed("attack"):
		if not ready_to_shoot:
			return
		
		fire()


func fire():
	if disabled:
		return
	
	fire_weapon.emit()
	ready_to_shoot = false
	cooldown_timer.start(cooldown)


func _on_cooldown_timer_timeout():
	ready_to_shoot = true

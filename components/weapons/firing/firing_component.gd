extends Node
class_name FiringComponent

signal fire_weapon

@export_range(0, 6) var base_cooldown : float = 1.0
var cooldown : float = 1.0

@onready var cooldown_timer : Timer = $CooldownTimer

var ready_to_shoot : bool = true
var disabled : bool = false


func _ready():
	cooldown = base_cooldown


func process_trigger(_just_pressed: bool, _held: bool) -> void:
	pass


func fire():
	if disabled:
		return
	
	fire_weapon.emit()
	ready_to_shoot = false
	cooldown_timer.start(cooldown)


func _on_cooldown_timer_timeout():
	ready_to_shoot = true


func apply_stats(mods: Dictionary) -> void:
	cooldown = clamp(mods["firing_speed"].get_values(base_cooldown), 0.1, 3.0)

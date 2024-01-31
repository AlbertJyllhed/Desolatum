extends Node
class_name FiringComponent

signal fire_weapon

@export_range(0, 6) var base_cooldown : float = 1.0
var cooldown : float = 1.0

@onready var cooldown_timer : Timer = $CooldownTimer

var ready_to_shoot : bool = true
var disabled : bool = false


func _ready():
	GameEvents.stats_changed.connect(on_stats_changed)
	cooldown = base_cooldown


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


func on_stats_changed(mods : Dictionary):
	cooldown = clamp(mods["firing_speed"].get_values(base_cooldown), 0.1, 3.0)
	#cooldown = clamp((base_cooldown + mods["firing_speed"][0]) * mods["firing_speed"][1], 0.1, 3.0)
	#print("firing_speed: " + str(cooldown))


func _on_cooldown_timer_timeout():
	ready_to_shoot = true

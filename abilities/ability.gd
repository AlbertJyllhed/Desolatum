extends Node2D
class_name Ability

@export var max_uses : int = 1
var uses : int = 0
@export_range(0, 20, 0.1, "or_greater") var recharge_time : float = 1.0

@onready var recharge_timer : Timer = $RechargeTimer


func _ready():
	uses = max_uses
	GameEvents.ability_updated.emit(0, uses)


func _physics_process(delta):
	if Input.is_action_just_pressed("use_ability"):
		try_use_ability()


func try_use_ability():
	if uses == 0:
		return
	
	use_ability()


func use_ability():
	uses = max(uses - 1, 0)
	recharge_timer.start(recharge_time)
	GameEvents.ability_updated.emit(recharge_time, uses)


func _on_recharge_timer_timeout():
	uses = min(uses + 1, max_uses)
	GameEvents.ability_updated.emit(0, uses)

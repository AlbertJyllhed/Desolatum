extends Node2D

@export var cooldown : float = 1.0

@onready var gun_component : GunComponent = $GunComponent
@onready var cooldown_timer : Timer = $Timer

var targets : Array[Node2D]


func _ready():
	cooldown_timer.wait_time = cooldown


func _on_target_locator_area_body_entered(body):
	targets.append(body)


func _on_target_locator_area_body_exited(body):
	targets.erase(body)


func _on_timer_timeout():
	if targets.size() == 0:
		return
	
	var direction = find_closest_target()
	gun_component.attack(direction)


func find_closest_target() -> Vector2:
	var closest_target = targets[0]
	for target in targets:
		if target.position.distance_to(position) < target.position.distance_to(closest_target.position):
			closest_target = target
	
	return closest_target.global_position

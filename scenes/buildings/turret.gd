extends Interactable
class_name Turret

@export var max_ammo : int = 60
var ammo : int
@export var cooldown : float = 1.0
@export var required_energy : int = 4

@onready var gun_component : GunComponent = $GunComponent
@onready var target_locator_ray : TargetLocatorRay = $TargetLocatorRay
@onready var cooldown_timer : Timer = $Timer

var targets : Array[Node2D]
var stats : PlayerStats = preload("res://resources/Data/player_stats.tres")


func _ready():
	ammo = max_ammo
	cooldown_timer.wait_time = cooldown
	cooldown_timer.start()


func show_details():
	if ammo > 0:
		return
	
	label.text = str(required_energy) + " energy"


func _on_target_locator_area_body_entered(body):
	targets.append(body)


func _on_target_locator_area_body_exited(body):
	targets.erase(body)


func _on_timer_timeout():
	if ammo == 0:
		cooldown_timer.stop()
		return
	
	if targets.size() == 0:
		return
	
	find_closest_target()


func find_closest_target():
	var closest_target = targets[0]
	for target in targets:
		if target.position.distance_to(position) < target.position.distance_to(closest_target.position):
			closest_target = target
	
	target_locator_ray.set_target(closest_target)
	if not target_locator_ray.has_target():
		return
	
	gun_component.attack(closest_target.global_position)
	ammo -= 1


func interact():
	if ammo > 0:
		return
	
	if stats.energy < required_energy:
		return
	
	stats.energy = max(stats.energy - required_energy, 0)
	GameEvents.energy_updated.emit(stats.energy)
	ammo = max_ammo
	hide_details()
	cooldown_timer.start()

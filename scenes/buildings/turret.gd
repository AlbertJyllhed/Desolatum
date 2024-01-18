extends Node2D
class_name Turret

@export var ammo : int = 45
@export var cooldown : float = 1.0

@onready var gun_component : GunComponent = $GunComponent
@onready var target_locator_ray : TargetLocatorRay = $TargetLocatorRay
@onready var light : Light2D = $Light
@onready var light_collision_shape : CollisionShape2D = $Light/Area2D/CollisionShape2D
@onready var cooldown_timer : Timer = $Timer

var targets : Array[Node2D]


func _ready():
	cooldown_timer.wait_time = cooldown
	cooldown_timer.start()


func _on_target_locator_area_body_entered(body):
	targets.append(body)


func _on_target_locator_area_body_exited(body):
	targets.erase(body)


func _on_timer_timeout():
	if ammo == 0:
		disable()
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
	ammo = max(ammo - 1, 0)


func disable():
	light.hide()
	light_collision_shape.disabled = true

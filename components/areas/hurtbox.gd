extends Area2D
class_name Hurtbox

signal hit(knockback, stun_time)

@export var health_component : Node
@export_range(0, 1.0) var damage_tick_delay : float = 0.5

@onready var timer : Timer = $Timer

var cooldowns : Dictionary = {} # Hitbox -> time (msec) it can hurt us again
var damage_multiplier : float = 1.0


func _physics_process(_delta):
	if not has_overlapping_areas():
		return
	
	for area in get_overlapping_areas():
		if not area is Hitbox:
			continue
		
		check_deal_damage(area)


func check_deal_damage(area: Hitbox):
	if not health_component:
		return
	
	var now = Time.get_ticks_msec()
	if cooldowns.get(area, 0) > now:
		return
	
	cooldowns[area] = now + int(damage_tick_delay * 1000)
	
	health_component.damage(area.damage * damage_multiplier)
	hit.emit(area.knockback_vector * area.knockback_multiplier, area.stun_time)
	
	# prune freed hitboxes so the dictionary doesn't grow
	for key in cooldowns.keys():
		if not is_instance_valid(key):
			cooldowns.erase(key)

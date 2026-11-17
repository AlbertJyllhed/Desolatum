extends Area2D
class_name Hurtbox

signal hit(knockback, stun_time)
## Emitted with the hitbox that just damaged us (after hit), for reactions
## that need to know where the hit came from.
signal hit_by(hitbox: Hitbox)

@export var health_component : Node
@export_range(0, 1.0) var damage_tick_delay : float = 0.5

@onready var timer : Timer = $Timer

var cooldowns : Dictionary = {} # Hitbox -> time (msec) it can hurt us again

## Cooldown end for hit-once hitboxes: effectively never.
const HIT_ONCE_COOLDOWN : int = 9223372036854775807
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
	
	# A hit-once hitbox never gets another go at us (the entry is pruned once it's freed).
	cooldowns[area] = HIT_ONCE_COOLDOWN if area.hit_once else now + int(damage_tick_delay * 1000)
	
	health_component.damage(area.damage * damage_multiplier)
	hit.emit(area.knockback_vector * area.knockback_multiplier, area.stun_time)
	hit_by.emit(area)
	HitStop.trigger(area.hit_stop)
	
	# prune freed hitboxes so the dictionary doesn't grow
	for key in cooldowns.keys():
		if not is_instance_valid(key):
			cooldowns.erase(key)

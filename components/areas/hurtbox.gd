extends Area2D
class_name Hurtbox

@export var health_component : Node
@export_range(0, 1.0) var damage_tick_delay : float = 0.5

@onready var timer : Timer = $Timer


func _physics_process(_delta):
	if not has_overlapping_areas():
		return
	
	var areas = get_overlapping_areas()
	for area in areas:
		if not area is Hitbox:
			return
		
		check_deal_damage(area)


func check_deal_damage(area):
	if health_component == null:
		return
	
	if not timer.is_stopped():
		return
	
	var hitbox = area as Hitbox
	health_component.damage(hitbox.damage)
	
	if owner is EnemyEntity:
		var base = owner as EnemyEntity
		base.knockback(hitbox.knockback_vector)
	
	timer.start(damage_tick_delay)

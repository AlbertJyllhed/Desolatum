extends Area2D
class_name Hurtbox

@export var health_component : Node
@export_range(0, 1.0) var damage_tick_delay : float = 0.5

@onready var timer : Timer = $Timer

var check_areas : Array[Area2D]


func _ready():
	timer.timeout.connect(check_deal_damage)


#func _physics_process(_delta):
	#if not has_overlapping_areas():
		#return
	#
	#var areas = get_overlapping_areas()
	#for area in areas:
		#if not area is Hitbox:
			#return
		#
		#check_deal_damage(area)


func check_deal_damage():
	if not health_component:
		return
	
	if check_areas.size() == 0:
		timer.stop()
		return
	
	#if not timer.is_stopped():
		#return
	
	var hitbox = check_areas[0] as Hitbox
	health_component.damage(hitbox.damage)
	
	if owner is EnemyEntity:
		var base = owner as EnemyEntity
		base.knockback(hitbox.knockback_vector)
	
	timer.start(damage_tick_delay)


func _on_area_entered(area):
	if not area is Hitbox:
		return
	
	if not timer.is_stopped():
		return
	
	check_areas.append(area)
	check_deal_damage()


func _on_area_exited(area):
	if not area is Hitbox:
		return
	
	check_areas.erase(area)

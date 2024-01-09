extends Area2D
class_name VelocityDamageArea

@export var health_component : HealthComponent
@export var self_damage : int = 1
@export var damage : int = 1

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

var active : bool = false


func _on_area_entered(area):
	if not active:
		return
	
	health_component.damage(self_damage)
	
	if area.owner is Entity:
		var other_entity = area.owner
		var other_health_component = other_entity.get_node("HealthComponent") as HealthComponent
		other_health_component.damage(damage)
		var direction = (other_entity.global_position - global_position).normalized()
		other_entity.move_in_direction(direction / 2, 320)
	
	active = false


func _on_body_entered(body):
	if not active:
		return
	
	health_component.damage(self_damage)
	active = false

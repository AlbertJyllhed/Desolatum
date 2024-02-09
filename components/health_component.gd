extends Node
class_name HealthComponent

signal died
signal health_changed(health)

@export var blood_particles : PackedScene
@export var max_health : float = 10
var current_health


func _ready():
	current_health = max_health


func damage(damage_amount : float):
	current_health = max(current_health - damage_amount, 0)
	health_changed.emit(current_health)
	spawn_particles()
	Callable(check_death).call_deferred()


func check_death():
	if current_health > 0:
		return
	
	died.emit()
	owner.queue_free()


func spawn_particles():
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	var blood_instance = blood_particles.instantiate()
	base_layer.call_deferred("add_child", blood_instance)
	blood_instance.global_position = owner.global_position

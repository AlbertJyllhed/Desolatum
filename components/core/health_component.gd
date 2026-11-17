@icon("res://addons/at-icons/node/heart.svg")
extends Node
class_name HealthComponent

signal died
## Emitted on any change to health, both damage and healing.
signal health_changed(health : float)
## Emitted only when damage is taken. Use this for hit reactions (flash, blood...).
signal damaged(amount : float)

@export var blood_particles : PackedScene
@export var max_health : float = 10

var current_health : float
var dead : bool = false


func _ready() -> void:
	current_health = max_health


func damage(damage_amount : float) -> void:
	if dead or current_health <= 0:
		return

	current_health = max(current_health - damage_amount, 0)
	damaged.emit(damage_amount)
	health_changed.emit(current_health)
	spawn_particles()
	Callable(check_death).call_deferred()


func heal(heal_amount : float) -> void:
	if dead:
		return

	current_health = min(current_health + heal_amount, max_health)
	health_changed.emit(current_health)


func check_death() -> void:
	if dead or current_health > 0:
		return

	dead = true
	died.emit()
	owner.queue_free()


func spawn_particles() -> void:
	if blood_particles == null:
		return

	var base_layer : Node = get_tree().get_first_node_in_group("base_layer")
	if base_layer == null:
		return

	# Deferred, as before: this can run in the middle of a physics callback.
	Pool.spawn.call_deferred(blood_particles, base_layer, owner.global_position)

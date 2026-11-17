extends Node2D
class_name RockFallMarker

## One floor tile with loose rock in the ceiling above it, part of a
## RockFallCluster. A little dust trickles down as a hint. fall() starts a
## heavy dust shower and drops a rock when the Timer runs out (its wait_time
## is the warning the player gets). Walking underneath does nothing.

const ROCK_FALL_SCENE: PackedScene = preload("uid://nrxgr1orcd1l")

## Share of the particles shown while the rock is just sitting there (the hint).
@export_range(0.0, 1.0, 0.05) var idle_dust_ratio: float = 0.25

@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var timer: Timer = $Timer

var _falling: bool = false


func _ready() -> void:
	particles.amount_ratio = idle_dust_ratio
	particles.emitting = true


## Starts the warning dust; the rock drops when the timer runs out.
func fall() -> void:
	if _falling:
		return
	_falling = true
	particles.amount_ratio = 1.0
	timer.start()


func _on_timer_timeout() -> void:
	var foreground_layer := get_tree().get_first_node_in_group("foreground_layer")
	var rock_fall_instance := ROCK_FALL_SCENE.instantiate() as Node2D
	foreground_layer.add_child(rock_fall_instance)
	rock_fall_instance.global_position = global_position
	queue_free()

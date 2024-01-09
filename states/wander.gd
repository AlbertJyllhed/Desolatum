extends EnemyState

@export var wander_range : float = 64.0
@export var min_update_time : float = 1.0
@export var max_update_time : float = 3.0


func body_entered(body):
	state_machine.transition_to("Chase", {"target" : body})


func timeout():
	state_machine.transition_to("Idle")


func enter(message = {}):
	state_machine.timer.start(randf_range(min_update_time, max_update_time))
	var wander_vector = Vector2(randi_range(-wander_range, wander_range), randi_range(-wander_range, wander_range))
	var wander_direction = wander_vector.normalized()
	enemy_entity.direction = wander_direction


func exit():
	state_machine.timer.stop()

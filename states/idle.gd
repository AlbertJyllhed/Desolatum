extends EnemyState

@export var min_transition_time : float = 0.1
@export var max_transition_time : float = 0.5


#func body_entered(body):
	#state_machine.transition_to("Chase", {"target" : body})


func timeout():
	if state_machine.target_locator_ray.has_target() or enemy_entity.aggressive:
		state_machine.transition_to("Hunt")
		return
	
	state_machine.transition_to("Wander")


func enter(message = {}):
	state_machine.animation_player.play("idle")
	enemy_entity.direction = Vector2.ZERO
	state_machine.timer.start(randf_range(min_transition_time, max_transition_time))


func exit():
	state_machine.timer.stop()

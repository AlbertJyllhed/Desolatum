extends EnemyState


func body_entered(body):
	state_machine.transition_to("Chase", {"target" : body})


func timeout():
	state_machine.transition_to("Wander")


func enter(message = {}):
	enemy_entity.direction = Vector2.ZERO
	state_machine.timer.start(randf_range(1.0, 3.0))


func exit():
	state_machine.timer.stop()

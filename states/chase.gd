extends EnemyState

@export var offset_amount : float = 40.0

@export var min_update_time : float = 1.0
@export var max_update_time : float = 2.0

var target : Node2D


func body_exited(body):
	state_machine.transition_to("Wander")


func timeout():
	if not is_instance_valid(target):
		return
	
	var offset = Vector2(randf_range(-offset_amount, offset_amount), randf_range(-offset_amount, offset_amount))
	enemy_entity.direction = ((target.global_position + offset) - enemy_entity.global_position).normalized()
	state_machine.timer.start(randf_range(min_update_time, max_update_time))


func enter(message = {}):
	if message.has("target"):
		target = message.values().front()
	
	state_machine.timer.start(randf_range(0.2, 0.5))


func exit():
	state_machine.timer.stop()
	state_machine.targeting_area.deactivate_detection()

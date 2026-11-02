extends EnemyState

@export var preferred_distance: float = 80.0


func physics_update(_delta: float) -> void:
	var player = state_machine.player
	if not is_instance_valid(player):
		return
	
	var to_player = player.global_position - enemy_entity.global_position
	var dist = to_player.length()
	if dist < preferred_distance - 16.0:
		enemy_entity.direction = -to_player.normalized()
	elif dist > preferred_distance + 16.0:
		enemy_entity.direction = to_player.normalized()
	else:
		enemy_entity.direction = Vector2.ZERO

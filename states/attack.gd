extends EnemyState

@export var cooldown : float = 0.5
@export var next_state = "Idle"


func timeout():
	attack()


func enter(message = {}):
	#prepare to attack
	enemy_entity.direction = Vector2.ZERO
	state_machine.timer.start(cooldown)


func attack():
	#handle all the attack logic
	state_machine.weapon.attack()
	state_machine.transition_to(next_state)


func exit():
	state_machine.timer.stop()

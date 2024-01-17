extends EnemyState

@export var next_state = "Idle"


func _ready():
	super._ready()
	owner.ready.connect(on_owner_ready)


func on_owner_ready():
	state_machine.animation_player.animation_finished.connect(on_animation_finished)


func enter(message = {}):
	#prepare to attack
	state_machine.animation_player.play("prepare_attack_right")
	enemy_entity.direction = Vector2.ZERO


func attack():
	#handle all the attack logic
	state_machine.animation_player.play("attack_right")
	state_machine.weapon.attack()


func on_animation_finished(animation : String):
	if animation == "prepare_attack_right":
		attack()
		return
	
	state_machine.transition_to(next_state)

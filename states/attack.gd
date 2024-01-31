extends EnemyState

@export var next_state = "Idle"
@export var dash : bool = false
@export var dash_speed : float = 80.0

var player_position : Vector2


func _ready():
	super._ready()
	owner.ready.connect(on_owner_ready)


func on_owner_ready():
	state_machine.animation_player.animation_finished.connect(on_animation_finished)


func enter(message = {}):
	#prepare to attack
	var player = get_tree().get_first_node_in_group("player") as Node2D
	player_position = player.global_position
	state_machine.animation_player.play("prepare_attack_right")
	enemy_entity.direction = Vector2.ZERO


func attack():
	#handle all the attack logic
	var direction = (player_position - owner.global_position).normalized()
	if dash:
		enemy_entity.move_in_direction(direction, dash_speed)
	
	enemy_entity.flip_sprite(direction)
	state_machine.animation_player.play("attack_right")
	state_machine.weapon.attack(player_position)


func on_animation_finished(animation : String):
	if animation == "prepare_attack_right":
		attack()
		return
	
	enemy_entity.direction = Vector2.ZERO
	state_machine.transition_to(next_state)

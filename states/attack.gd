extends EnemyState

@export var next_state = "Idle"
@export var dash : bool = false
@export var dash_speed : float = 80.0

@export_group("Aiming")
## Keep following the player during the wind-up instead of aiming once at the start
@export var track_target : bool = false
## Stop following this many seconds before the shot, so the player can still dodge
@export var aim_lock_time : float = 0.2

var player_position : Vector2
var _is_preparing : bool = false


func _ready():
	super._ready()
	owner.ready.connect(on_owner_ready)


func on_owner_ready():
	state_machine.animation_player.animation_finished.connect(on_animation_finished)


func enter(_message = {}):
	#prepare to attack
	if (is_instance_valid(state_machine.player)):
		player_position = state_machine.player.global_position
	
	var weapon = state_machine.weapon
	if is_instance_valid(weapon.building_target):
		player_position = weapon.building_target.global_position
	
	state_machine.animation_player.play("prepare_attack_right")
	enemy_entity.direction = Vector2.ZERO
	_is_preparing = true


func exit():
	_is_preparing = false


func physics_update(_delta: float) -> void:
	if not track_target or not _is_preparing:
		return

	# Buildings don't move, so only the player needs tracking
	if is_instance_valid(state_machine.weapon.building_target):
		return

	var player: Player = state_machine.player
	if not is_instance_valid(player):
		return

	var anim: AnimationPlayer = state_machine.animation_player
	var time_left: float = anim.current_animation_length - anim.current_animation_position
	if time_left <= aim_lock_time:
		return # aim is locked in

	player_position = player.global_position


func attack():
	#handle all the attack logic
	_is_preparing = false
	var direction = (player_position - owner.global_position).normalized()
	if dash:
		enemy_entity.move_in_direction(direction, dash_speed)
	
	enemy_entity.flip_sprite(direction)
	state_machine.animation_player.play("attack_right")
	state_machine.weapon.attack(player_position)


func on_animation_finished(animation : String):
	if animation == "prepare_attack_right":
		attack()
	
	if animation == "attack_right":
		enemy_entity.direction = Vector2.ZERO
		state_machine.transition_to(next_state)

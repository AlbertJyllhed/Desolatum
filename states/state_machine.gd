extends Node
class_name StateMachine

signal transitioned(state_name)

#@export var targeting_area : TargetLocatorArea
@export var animation_player : AnimationPlayer
@export var target_locator_ray : TargetLocatorRay
@export var weapon : EnemyWeaponBase
@export var timer : Timer

var player : Player
var current_state : State


func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	for child in get_children():
		child.state_machine = self
	
	#if targeting_area:
		#targeting_area.body_entered.connect(on_target_body_entered)
		#targeting_area.body_exited.connect(on_target_body_exited)
	
	if target_locator_ray:
		target_locator_ray.set_target(player)
	
	if weapon:
		weapon.has_target.connect(on_attack_entered)
	
	if timer:
		timer.timeout.connect(on_timeout)
	
	current_state = get_child(0)
	current_state.enter()


#func _physics_process(delta):
	#current_state.physics_update(delta)


#func on_target_body_entered(body):
	#current_state.body_entered(body)


#func on_target_body_exited(body):
	#current_state.body_exited(body)


func on_attack_entered():
	if not current_state.interruptible:
		return
	
	transition_to("Attack")


func on_timeout():
	current_state.timeout()


func transition_to(target_state_name : String, message : Dictionary = {}):
	if not has_node(target_state_name):
		push_warning("State '%s' not found on %s" % [target_state_name, owner.name])
		return
	
	current_state.exit()
	current_state = get_node(target_state_name)
	current_state.enter(message)
	transitioned.emit(current_state.name)
	#print(current_state.name)

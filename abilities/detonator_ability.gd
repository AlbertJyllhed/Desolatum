extends Node2D

@export var bomb_scene : PackedScene
@export var max_charges : int = 3
@export var recharge_time : float = 10.0

@onready var pivot : Node2D = $Pivot
@onready var timer : Timer = $Timer

var active_charges = []
var throw_direction : Vector2
var charges : int


func _ready():
	charges = max_charges


func _physics_process(delta):
	throw_direction = get_global_mouse_position()
	look_at(throw_direction)
	
	if charges == 0:
		return
	
	if Input.is_action_just_pressed("alt_attack"):
		var base_layer = get_tree().get_first_node_in_group("base_layer")
		var direction = (throw_direction - global_position).normalized()
		var bomb_instance = bomb_scene.instantiate()
		base_layer.add_child(bomb_instance)
		bomb_instance.global_position = pivot.global_position
		bomb_instance.setup(direction, 100, 1, false)
		active_charges.append(bomb_instance)
		charges = max(charges - 1, 0)


func is_active() -> bool:
	if active_charges.size() > 0:
		return true
	
	return false


func activate():
	for charge in active_charges:
		charge.explode()
	
	active_charges.clear()
	timer.start(recharge_time)


func _on_timer_timeout():
	charges = min(charges + 1, max_charges)

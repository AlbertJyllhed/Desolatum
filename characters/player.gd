extends CharacterBody2D
class_name Player

var move_speed = 80
@export var acceleration = 600
@export var friction = 500

@onready var health_component : HealthComponent = $HealthComponent
@onready var energy_gain_component : EnergyGainComponent = $EnergyGainComponent
@onready var footstep_component : FootstepComponent = $FootstepComponent
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var flash_light : FlashLight = $FlashLight

var stats : PlayerStats = preload("res://resources/Data/player_stats.tres")
var inventory_scene = preload("res://components/weapon_inventory_component.tscn")
var inventory_instance : WeaponInventoryComponent
var top_left_limit : Vector2i
var bottom_right_limit : Vector2i


func _ready():
	GameEvents.stats_changed.connect(on_stats_changed)
	add_to_group("player")
	stats.update_stats()
	health_component.setup(stats)
	energy_gain_component.setup(stats)
	var camera = get_viewport().get_camera_2d() as PlayerCamera
	camera.set_target(self)
	
	if top_left_limit == Vector2i.ZERO:
		return
	
	camera.limit_top = top_left_limit.y * 16
	camera.limit_left = top_left_limit.x * 16
	camera.limit_bottom = bottom_right_limit.y * 16
	camera.limit_right = bottom_right_limit.x * 16


func setup_camera(top_left : Vector2i, bottom_right : Vector2i):
	top_left_limit = top_left
	bottom_right_limit = bottom_right


func setup_inventory():
	inventory_instance = inventory_scene.instantiate()
	add_child(inventory_instance)
	inventory_instance.global_position = global_position
	inventory_instance.setup(stats)


func _physics_process(delta):
	var aim_vector = get_local_mouse_position().normalized()
	animation_tree.set("parameters/idle/blend_position", aim_vector)
	animation_tree.set("parameters/walk/blend_position", aim_vector)
	
	# Get the input direction and handle the movement/deceleration.
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		animation_state.travel("walk")
		footstep_component.start_footsteps()
		velocity = velocity.move_toward(input_vector * move_speed, acceleration * delta)
	else:
		animation_state.travel("idle")
		footstep_component.stop_footsteps()
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		global_position = round(global_position)
	
	move_and_slide()


func on_stats_changed(mods : Dictionary):
	move_speed = mods["move_speed"].get_values(stats.base_move_speed)
	#move_speed = (stats.base_move_speed + mods["move_speed"][0]) * mods["move_speed"][1]


func set_active(value : bool):
	set_physics_process(value)
	$Sprite2D.visible = value
	if value == true:
		return
	
	if not inventory_instance:
		return
	
	inventory_instance.queue_free()

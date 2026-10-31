extends CharacterBody2D
class_name Player

var move_speed : float = 80
@export var acceleration : float = 600
@export var friction : float = 500
@export var combat_enabled : bool = true

@onready var health_component : PlayerHealthComponent = $HealthComponent
@onready var energy_gain_component : EnergyGainComponent = $EnergyGainComponent
@onready var build_manager : BuildManager = $BuildManager
@onready var footstep_component : FootstepComponent = $FootstepComponent
@onready var animation_tree : AnimationTree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var flash_light : FlashLight = $FlashLight

var inventory_scene = preload("res://components/weapon_inventory_component.tscn")
var inventory_instance : WeaponInventoryComponent


func _ready():
	GameEvents.stats_changed.connect(on_stats_changed)
	add_to_group("player")
	if combat_enabled:
		setup_combat()
	
	health_component.setup()
	energy_gain_component.setup()
	var camera = get_viewport().get_camera_2d() as PlayerCamera
	camera.set_target(self)
	Run.state.update_stats()
	Run.state.add_upgrades()
	collision_mask |= 1 << 14


func setup_combat():
	setup_inventory()
	build_manager.setup(inventory_instance)


func setup_inventory():
	inventory_instance = inventory_scene.instantiate() as WeaponInventoryComponent
	add_child(inventory_instance)
	inventory_instance.global_position = global_position
	inventory_instance.setup()


func _physics_process(delta):
	var aim_vector = get_local_mouse_position().normalized()
	if GamepadManager.using_gamepad:
		aim_vector = GamepadManager.get_aim_direction()
	
	animation_tree.set("parameters/idle/blend_position", aim_vector)
	animation_tree.set("parameters/walk/blend_position", aim_vector)
	
	# Get the input direction and handle the movement/deceleration.
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
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
	move_speed = mods["move_speed"].get_values(Run.config.base_move_speed)


func set_active(value : bool):
	set_physics_process(value)
	animation_state.travel("idle")
	footstep_component.stop_footsteps()
	if build_manager:
		build_manager.set_active(false) if not value else null
	if inventory_instance:
		inventory_instance.deactivate(!value)

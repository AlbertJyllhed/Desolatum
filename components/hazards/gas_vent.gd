extends Node2D
class_name GasVent

## A vent that cycles IDLE -> WARNING -> ACTIVE. Resting shows no gas. The
## warning is a few pixels rising around the vent (WarningParticles). While
## venting, GasPuffs spreads gas puffs out from the centre. The Hitbox gets one
## circle shape per puff, sized to the part of the puff that is drawn as cloud,
## so you only take damage where you can see gas. Puffs that are still fading
## out after venting stops keep hurting until they're gone.

@export var idle_time: float = 4.0
@export var warning_time: float = 1.0
@export var active_time: float = 2.5
## Extra pixels on each puff's hitbox, to cover the thin strip where two
## overlapping puffs together draw gas that neither would draw alone.
@export var hitbox_padding: float = 1.0

## Puffs whose visible part is smaller than this don't get a hitbox.
const MIN_HIT_RADIUS: float = 0.5
## Used when the cloud material has no edge_threshold set.
const DEFAULT_EDGE_THRESHOLD: float = 0.15

@onready var hitbox: Hitbox = $Hitbox
@onready var warning_particles: GPUParticles2D = $WarningParticles
## Drawn into GasViewport; the GasCloud sprite turns that into the pixel cloud.
@onready var gas_puffs: GasPuffs = $GasViewport/GasPuffs
@onready var gas_cloud: Sprite2D = $GasCloud
@onready var timer: Timer = $Timer

enum State { IDLE, WARNING, ACTIVE }
var state := State.IDLE

## One shape per possible puff, reused as puffs come and go.
var _puff_shapes: Array[CollisionShape2D] = []
## Gas amount the cloud shader needs to draw a pixel as cloud.
var _edge_threshold: float = DEFAULT_EDGE_THRESHOLD


func _ready() -> void:
	# The scene's own circle only shows the rough gas area in the editor.
	hitbox.collision_shape.disabled = true
	_read_edge_threshold()
	_create_puff_shapes()
	# Run after GasPuffs has moved this frame's puffs.
	process_physics_priority = 1
	warning_particles.emitting = false
	gas_puffs.emitting = false
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	# Randomize so vents on a level don't all pulse in sync
	timer.start(randf_range(0.0, idle_time))


func _physics_process(_delta: float) -> void:
	_sync_puff_shapes()


func _read_edge_threshold() -> void:
	var cloud_material := gas_cloud.material as ShaderMaterial
	if cloud_material == null:
		return
	var value: Variant = cloud_material.get_shader_parameter("edge_threshold")
	if value is float:
		_edge_threshold = value


func _create_puff_shapes() -> void:
	for i in gas_puffs.max_puffs:
		var shape_node := CollisionShape2D.new()
		shape_node.shape = CircleShape2D.new()
		shape_node.disabled = true
		hitbox.add_child(shape_node)
		_puff_shapes.append(shape_node)


## Moves one hitbox shape onto each puff and turns the rest off.
func _sync_puff_shapes() -> void:
	var puffs: Array[GasPuffs.Puff] = gas_puffs.puffs
	for i in _puff_shapes.size():
		var shape_node: CollisionShape2D = _puff_shapes[i]
		var hit_radius: float = 0.0
		if i < puffs.size():
			hit_radius = gas_puffs.get_visible_radius(puffs[i], _edge_threshold)
		if hit_radius < MIN_HIT_RADIUS:
			shape_node.disabled = true
			continue
		shape_node.position = puffs[i].position
		(shape_node.shape as CircleShape2D).radius = hit_radius + hitbox_padding
		shape_node.disabled = false


func _on_timer_timeout() -> void:
	match state:
		State.IDLE:
			state = State.WARNING
			warning_particles.emitting = true
			timer.start(warning_time)
		State.WARNING:
			state = State.ACTIVE
			warning_particles.emitting = false
			gas_puffs.emitting = true
			timer.start(active_time)
		State.ACTIVE:
			state = State.IDLE
			gas_puffs.emitting = false
			timer.start(idle_time)

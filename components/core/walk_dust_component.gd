extends Node
class_name WalkDustComponent

## Spawns a dust puff under a CharacterBody2D when it starts moving or turns
## sharply. Puffs come from the pool and fly opposite the movement.

## Body to watch. Uses the owner if left empty.
@export var body : CharacterBody2D
## One-shot dust effect (needs a PooledEffect child).
@export var dust_scene : PackedScene
## Offset from the body's position to its feet.
@export var offset : Vector2 = Vector2.ZERO
## Counts as moving above this speed, in pixels per second.
@export var min_speed : float = 15.0
## A turn bigger than this (degrees) since the last puff makes a new puff.
@export_range(10, 180, 1) var turn_angle : float = 100.0
## Least time between two puffs, in seconds.
@export var cooldown : float = 0.15

var _base_layer : Node
var _was_moving : bool = false
## Movement direction when the last puff was made.
var _puff_direction : Vector2 = Vector2.ZERO
var _cooldown_left : float = 0.0


func _ready() -> void:
	if not body:
		body = owner as CharacterBody2D
	_base_layer = get_tree().get_first_node_in_group("base_layer")


func _physics_process(delta : float) -> void:
	if not body or not dust_scene:
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)

	var moving : bool = body.velocity.length() > min_speed
	if not moving:
		_was_moving = false
		return

	var direction : Vector2 = body.velocity.normalized()
	if not _was_moving:
		_was_moving = true
		_puff(direction)
	elif absf(rad_to_deg(direction.angle_to(_puff_direction))) > turn_angle:
		_puff(direction)


func _puff(direction : Vector2) -> void:
	# The new direction always counts, so a turn during the cooldown
	# doesn't trigger a late puff.
	_puff_direction = direction
	if _cooldown_left > 0.0:
		return
	if not is_instance_valid(_base_layer):
		_base_layer = get_tree().get_first_node_in_group("base_layer")
		if not _base_layer:
			return
	_cooldown_left = cooldown
	Pool.spawn(dust_scene, _base_layer, body.global_position + offset, (-direction).angle())

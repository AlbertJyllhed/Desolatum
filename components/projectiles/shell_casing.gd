extends Sprite2D
class_name ShellCasing

## A spent casing ejected by a gun. The game is top-down, so the bounce is
## faked: the casing tracks a height above its spot on the floor and is drawn
## that many pixels higher. It arcs out, bounces, lies still for a while,
## fades and goes back to the pool. Spawn it with Pool.spawn(), then call
## launch(). Needs a PooledEffect child.

## Pull toward the floor, in pixels per second squared.
@export var gravity : float = 400.0
## Upward speed when ejected, in pixels per second (random between x and y).
@export var launch_up_speed : Vector2 = Vector2(60, 90)
## Sideways speed along the floor when ejected (random between x and y).
@export var launch_speed : Vector2 = Vector2(20, 45)
## Random spread of the eject direction, in degrees.
@export_range(0, 180, 1) var launch_spread : float = 35.0
## How much upward speed is kept on each bounce (0..1).
@export_range(0, 1, 0.05) var bounciness : float = 0.4
## How much floor speed is kept on each bounce (0..1).
@export_range(0, 1, 0.05) var floor_friction : float = 0.5
## Bounces slower than this (pixels per second) just stop.
@export var min_bounce_speed : float = 15.0
## Spin while in the air, in degrees per second (random between x and y).
@export var spin_speed : Vector2 = Vector2(540, 900)
## Seconds the casing lies on the floor before fading.
@export var lifetime : float = 3.0
## Seconds the fade takes.
@export var fade_time : float = 0.5

## Spot on the floor below the casing (global).
var _floor_position : Vector2
var _height : float = 0.0
var _up_speed : float = 0.0
var _floor_velocity : Vector2
var _spin : float = 0.0
var _landed : bool = true
var _time_on_floor : float = 0.0


func _ready() -> void:
	set_physics_process(false)


## Throws the casing out toward [param direction] (it doesn't need to be
## normalized). [param start_height] is how far above the floor it starts,
## e.g. the gun's height above the player's feet.
func launch(direction : Vector2, start_height : float = 6.0) -> void:
	_reset_state()
	var spread := deg_to_rad(randf_range(-launch_spread, launch_spread))
	_floor_velocity = direction.normalized().rotated(spread) * randf_range(launch_speed.x, launch_speed.y)
	_up_speed = randf_range(launch_up_speed.x, launch_up_speed.y)
	_spin = deg_to_rad(randf_range(spin_speed.x, spin_speed.y)) * (1.0 if randf() < 0.5 else -1.0)
	_height = start_height
	_floor_position = global_position + Vector2(0, start_height)
	_landed = false
	set_physics_process(true)
	_update_draw_position()


func _physics_process(delta : float) -> void:
	if not _landed:
		_fly(delta)
		return

	_time_on_floor += delta
	if _time_on_floor >= lifetime:
		var fade := (_time_on_floor - lifetime) / maxf(fade_time, 0.001)
		modulate.a = 1.0 - clampf(fade, 0.0, 1.0)
		if fade >= 1.0:
			set_physics_process(false)
			var effect := PooledEffect.find_in(self)
			if effect:
				effect.release()
			else:
				queue_free()


func _fly(delta : float) -> void:
	_floor_position += _floor_velocity * delta
	_up_speed -= gravity * delta
	_height += _up_speed * delta
	rotation += _spin * delta

	if _height <= 0.0:
		_height = 0.0
		if absf(_up_speed) * bounciness > min_bounce_speed:
			_up_speed = -_up_speed * bounciness
			_floor_velocity *= floor_friction
			_spin *= 0.5
		else:
			_land()
	_update_draw_position()


func _land() -> void:
	_landed = true
	_up_speed = 0.0
	_floor_velocity = Vector2.ZERO
	# Snap to 45 degree steps so the pixels stay clean while it lies still.
	rotation = snappedf(rotation, PI / 4.0)


func _update_draw_position() -> void:
	global_position = (_floor_position - Vector2(0, _height)).round()


func _reset_state() -> void:
	modulate.a = 1.0
	_time_on_floor = 0.0
	_height = 0.0
	_up_speed = 0.0
	_floor_velocity = Vector2.ZERO
	_landed = true


## Called by PooledEffect when the pool reuses this casing.
func _on_pool_reset() -> void:
	_reset_state()
	set_physics_process(false)

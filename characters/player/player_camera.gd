extends Camera2D
class_name PlayerCamera

## Follows the player, leaning toward the aim. Two kinds of camera feedback
## are added on top through the camera's offset, so the follow smoothing never
## flattens them:
## - recoil: a kick in one direction that eases back (weapons, see kick())
## - shake: a wobble that fades out (explosions, hits, see add_shake())

var target : Node2D
var target_position : Vector2
var padding : int = 50

@export_group("Shake")
## Largest shake offset in pixels, reached at full shake (amount 1).
@export var max_shake_offset : float = 8.0
## How much shake fades per second (shake amounts go from 0 to 1).
@export var shake_decay : float = 1.8
## How fast the shake wobbles.
@export var shake_frequency : float = 30.0
## World shakes (add_shake_at) fade to nothing at this distance in pixels.
@export var shake_falloff_distance : float = 220.0
## Shake the low rumble before a wave builds up to (0 to 1, see GameEvents.chaos_warning).
@export var warning_rumble : float = 0.3

@export_group("Recoil")
## How fast a kick eases back to the centre (higher = snappier).
@export var recoil_return_speed : float = 20.0

## Current shake, 0 to 1 (1 = max_shake_offset pixels).
var trauma : float = 0.0
var recoil_offset : Vector2 = Vector2.ZERO
## Steady shake that doesn't fade on its own, 0 to 1. Used for the rumble before a wave.
var rumble : float = 0.0

var _noise := FastNoiseLite.new()
var _noise_time : float = 0.0
var _rumble_tween : Tween


func _ready():
	GameEvents.set_camera_target.connect(set_target)
	GameEvents.chaos_warning.connect(_on_chaos_warning)
	GameEvents.wave_updated.connect(_on_wave_updated)
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.0
	_noise.seed = randi()


func set_limits(rect: Rect2i):
	limit_left = rect.position.x * Tiles.CELL_SIZE
	limit_top = rect.position.y * Tiles.CELL_SIZE
	limit_right = rect.end.x * Tiles.CELL_SIZE
	limit_bottom = rect.end.y * Tiles.CELL_SIZE


func set_target(new_target : Node2D):
	target = new_target


func update_target_position():
	if not is_instance_valid(target):
		return position

	if not target is Player:
		return target.position

	var mouse_position = get_local_mouse_position()
	if GamepadManager.using_gamepad:
		mouse_position = GamepadManager.get_aim_direction()

	mouse_position.x = clamp(mouse_position.x, -padding, padding)
	mouse_position.y = clamp(mouse_position.y, -padding, padding)

	var ret = target.position + mouse_position
	ret = round(ret)
	return ret


func _physics_process(delta):
	target_position = update_target_position()
	position = position.lerp(target_position, 1.0 - exp(-10.0 * delta)).round()
	_update_feedback(delta)


## Kicks the camera [param distance] pixels toward [param direction] (pass the
## opposite of the firing direction for recoil). It eases back on its own.
func kick(direction : Vector2, distance : float) -> void:
	if direction == Vector2.ZERO or distance <= 0.0:
		return
	recoil_offset = direction.normalized() * distance


## Adds shake (0 to 1, e.g. 0.2 small, 0.6 big). Stacks up to 1.
func add_shake(amount : float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


## Adds shake for something happening at [param world_position]: full strength
## next to the camera, fading to nothing at shake_falloff_distance.
func add_shake_at(amount : float, world_position : Vector2) -> void:
	var distance : float = get_screen_center_position().distance_to(world_position)
	var falloff : float = 1.0 - clampf(distance / shake_falloff_distance, 0.0, 1.0)
	add_shake(amount * falloff)


## The rumble builds up over the warning, then stops when the wave starts.
func _on_chaos_warning(duration : float) -> void:
	if _rumble_tween:
		_rumble_tween.kill()
	_rumble_tween = create_tween()
	_rumble_tween.tween_property(self, "rumble", warning_rumble, duration)


func _on_wave_updated(_phase : int) -> void:
	if _rumble_tween:
		_rumble_tween.kill()
	rumble = 0.0


func _update_feedback(delta : float) -> void:
	recoil_offset = recoil_offset.lerp(Vector2.ZERO, 1.0 - exp(-recoil_return_speed * delta))
	trauma = maxf(trauma - shake_decay * delta, 0.0)

	var shake := Vector2.ZERO
	var amount : float = maxf(trauma, rumble)
	if amount > 0.0:
		_noise_time += delta * shake_frequency
		var strength : float = amount * max_shake_offset
		shake = Vector2(_noise.get_noise_2d(_noise_time, 0.0), _noise.get_noise_2d(0.0, _noise_time)) * strength

	# Whole pixels only, so the pixel art stays crisp.
	offset = (recoil_offset + shake).round()

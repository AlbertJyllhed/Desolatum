extends Node
class_name DissolveComponent

## Waits, then dissolves a sprite away pixel by pixel (pixel_dissolve.gdshader)
## and removes the scene it belongs to: back to the pool if the owner has a
## PooledEffect child, otherwise freed. Used by blood stains, and meant for
## enemy corpses later.
## It gives the sprite its own dissolve material, replacing any material the
## sprite had. Pooled scenes start over each time they're spawned again.

signal dissolved

const DISSOLVE_SHADER := preload("res://resources/shaders/pixel_dissolve.gdshader")

## Sprite (or any CanvasItem) to dissolve. Uses the parent if left empty.
@export var sprite : CanvasItem
## Seconds before the dissolve starts.
@export var delay : float = 10.0
## Seconds the dissolve takes.
@export var duration : float = 1.5
## Start counting down as soon as the scene is added. Off: call start().
@export var autostart : bool = true
## Remove the owner scene when the dissolve is done.
@export var remove_owner : bool = true

var _material : ShaderMaterial
var _tween : Tween


func _ready() -> void:
	if not sprite:
		sprite = get_parent() as CanvasItem
	if not sprite:
		push_warning("DissolveComponent '%s' has no CanvasItem to dissolve" % get_path())
		return
	_material = ShaderMaterial.new()
	_material.shader = DISSOLVE_SHADER
	sprite.material = _material
	if autostart:
		start()


func _enter_tree() -> void:
	# Pooled scenes come back here; _ready only runs the first time.
	if is_node_ready() and autostart:
		start()


## Shows the sprite fully again and starts the countdown to the dissolve.
func start() -> void:
	if not _material:
		return
	if _tween:
		_tween.kill()
	_set_amount(0.0)
	_material.set_shader_parameter(&"seed", randf() * 100.0)
	_tween = create_tween()
	_tween.tween_interval(delay)
	_tween.tween_method(_set_amount, 0.0, 1.0, duration)
	_tween.tween_callback(_finish)


func _set_amount(amount : float) -> void:
	_material.set_shader_parameter(&"dissolve_amount", amount)


func _finish() -> void:
	dissolved.emit()
	if not remove_owner or not owner:
		return
	var effect := PooledEffect.find_in(owner)
	if effect:
		effect.release()
	else:
		owner.queue_free()

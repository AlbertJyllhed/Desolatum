extends Node
class_name LightGlowComponent

## Keeps a sprite at full brightness in the dark. Add it as a child of the
## sprite (or set [member sprite]). It draws a copy of the sprite's shape into
## the scene's LightMap, which leaves those pixels unlit. Does nothing when
## the scene has no LightMap.

const GLOW_SHADER := preload("res://resources/shaders/light_glow.gdshader")

## Sprite that glows. Uses the parent if left empty.
@export var sprite : Sprite2D

var _shape : Sprite2D


func _ready() -> void:
	if not sprite:
		sprite = get_parent() as Sprite2D
	if not sprite:
		push_warning("LightGlowComponent '%s' has no Sprite2D to follow" % get_path())
		return
	_create_shape()


func _enter_tree() -> void:
	# Pooled or re-added nodes come back here; _ready only runs the first time.
	if is_node_ready():
		_create_shape()


func _create_shape() -> void:
	if not sprite or _shape:
		return
	var light_map := LightMap.find(get_tree())
	if not light_map:
		return

	_shape = Sprite2D.new()
	_shape.name = "%s_glow" % sprite.name
	_shape.visibility_layer = LightMap.GLOW_LAYER
	_shape.light_mask = 0
	var material_instance := ShaderMaterial.new()
	material_instance.shader = GLOW_SHADER
	_shape.material = material_instance
	light_map.glow_root.add_child(_shape)
	RenderingServer.frame_pre_draw.connect(_sync)
	_sync()


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_sync):
		RenderingServer.frame_pre_draw.disconnect(_sync)
	if is_instance_valid(_shape):
		_shape.queue_free()
	_shape = null


## Copies the sprite's look and place right before each frame is drawn.
func _sync() -> void:
	if not is_instance_valid(sprite) or not is_instance_valid(_shape):
		return
	_shape.visible = sprite.is_visible_in_tree()
	_shape.texture = sprite.texture
	_shape.hframes = sprite.hframes
	_shape.vframes = sprite.vframes
	_shape.frame = sprite.frame
	_shape.region_enabled = sprite.region_enabled
	_shape.region_rect = sprite.region_rect
	_shape.centered = sprite.centered
	_shape.offset = sprite.offset
	_shape.flip_h = sprite.flip_h
	_shape.flip_v = sprite.flip_v
	_shape.global_transform = sprite.global_transform

extends Entity
class_name AutoPickup

@export var item : Item
@export var variants : int = 3
@export var min_frame : int = 0
@export var max_frame : int = 2

@onready var sprite : Sprite2D = $Sprite2D

## Collect pop: grow to POP_SCALE, then shrink into the collector.
const POP_SCALE : float = 1.4
const POP_GROW_TIME : float = 0.04
const POP_SHRINK_TIME : float = 0.08

var _collected : bool = false
var _pop_collector : Node2D
var _pop_start : Vector2


func _ready():
	sprite.texture = item.icon
	sprite.hframes = variants
	sprite.frame = randi_range(min_frame, max_frame)
	var random_rotation = randi_range(-8, 8)
	global_rotation = random_rotation
	var random_direction = Vector2(randi_range(-1, 1), randi_range(-1, 1))
	move_in_direction(random_direction, max_speed)


func set_item(new_item : Item):
	item = new_item


func _physics_process(_delta):
	accelerate_in_direction(Vector2.ZERO, 0, 100.0)
	move_and_slide()


## Collects the item right away, then plays a short pop: the pickup grows a
## little and shrinks into [param collector] before it's removed.
## Returns false if it was already collected.
func pick_up(collector: Node2D = null) -> bool:
	if _collected:
		return false
	_collected = true
	GameEvents.item_picked_up.emit(item)

	if not is_instance_valid(collector):
		queue_free()
		return true

	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	_pop_collector = collector
	_pop_start = global_position
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2.ONE * POP_SCALE, POP_GROW_TIME)
	tween.tween_method(_pop_step, 0.0, 1.0, POP_SHRINK_TIME)
	tween.tween_callback(queue_free)
	return true


## t goes 0..1: slide into the collector while shrinking to nothing.
func _pop_step(t: float) -> void:
	if is_instance_valid(_pop_collector):
		global_position = _pop_start.lerp(_pop_collector.global_position, t).round()
	sprite.scale = Vector2.ONE * POP_SCALE * (1.0 - t)

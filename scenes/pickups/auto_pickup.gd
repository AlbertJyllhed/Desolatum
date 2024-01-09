extends Entity
class_name AutoPickup

@export var item : Item
@export var variants : int = 3
@export var min_frame : int = 0
@export var max_frame : int = 2

@onready var sprite : Sprite2D = $Sprite2D


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


func pick_up():
	GameEvents.item_picked_up.emit(item)
	queue_free()

extends Interactable

@onready var drop_component = $DropComponent
@onready var sprite : Sprite2D = $Sprite2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D


func show_details():
	label.text = "Open Crate"


func interact():
	drop_component.on_died()
	sprite.frame += 1
	collision_shape.queue_free()

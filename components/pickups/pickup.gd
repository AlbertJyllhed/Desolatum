extends Interactable
class_name Pickup

@export var item : Item

@onready var sprite : Sprite2D = $Sprite2D


func set_item(new_item : Item):
	item = new_item
	call_deferred("set_icon")


func set_icon():
	if not item.icon:
		return
	
	sprite.texture = item.icon


func show_details():
	label.text = item.name


func interact():
	GameEvents.item_picked_up.emit(item)
	queue_free()

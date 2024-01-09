extends Interactable
class_name Pickup

@export var item : Item


func set_item(new_item : Item):
	item = new_item


func show_details():
	label.text = item.name


func interact():
	GameEvents.item_picked_up.emit(item)
	queue_free()

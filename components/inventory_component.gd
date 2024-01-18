extends Node2D
class_name InventoryComponent

var deactivated : bool = false

var items = []
var max_index : int = 0
var index : int


func _physics_process(delta):
	if Input.is_action_just_released("scroll_down"):
		next_slot()
	
	if Input.is_action_just_released("scroll_up"):
		prev_slot()


func deactivate(value : bool):
	deactivated = value
	if deactivated:
		hide()
		return
	
	show()


func next_slot():
	if deactivated:
		return
	
	index = min(index + 1, max_index)


func prev_slot():
	if deactivated:
		return
	
	index = max(index - 1, 0)


func add_item(new_item : Item):
	pass

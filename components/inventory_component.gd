extends Node2D
class_name InventoryComponent

var deactivated : bool = false

var items = []
var max_index : int = 0
var index : int


func deactivate(value : bool):
	deactivated = value
	if deactivated:
		hide()
		return
	
	show()


func next_slot():
	if deactivated:
		return
	
	index += 1
	if index > max_index:
		index = 0


func prev_slot():
	if deactivated:
		return
	
	index -= 1
	if index < 0:
		index = max_index


func add_item(new_item : Item):
	pass

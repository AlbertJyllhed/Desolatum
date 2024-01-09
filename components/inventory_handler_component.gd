extends Node2D

var inventories : Array[InventoryComponent]
var index = 0


func _ready():
	if get_child_count() == 0:
		return
	
	for child in get_children():
		var inventory = child as InventoryComponent
		inventories.append(inventory)
		inventory.deactivate(true)
	
	inventories[index].deactivate(false)


func _physics_process(_delta):
	if Input.is_action_just_pressed("alt_attack"):
		for inventory in inventories:
			inventory.deactivate(true)
		
		index += 1
		if index > inventories.size() - 1:
			index = 0
		
		inventories[index].deactivate(false)
	
	if Input.is_action_just_released("scroll_down"):
		inventories[index].next_slot()
	
	if Input.is_action_just_released("scroll_up"):
		inventories[index].prev_slot()

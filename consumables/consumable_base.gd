extends Node2D
class_name Consumable

signal used

var player : Player
var item : Item
var remaining : int = 0


func setup(new_player : Player, new_item : Item):
	player = new_player
	item = new_item
	remaining = item.amount
	print("set: " + item.id)


func add_item(new_item : Item):
	remaining += new_item.amount
	print("added: " + str(new_item.amount))


func _physics_process(delta):
	if Input.is_action_just_pressed("use_consumable"):
		use_consumable()


func use_consumable():
	remaining = max(remaining - 1, 0)
	print(remaining)
	if remaining > 0:
		return
	
	used.emit()
	queue_free()

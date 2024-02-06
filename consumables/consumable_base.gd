extends Node2D
class_name Consumable

@export var remaining : int = 1


func _physics_process(delta):
	if Input.is_action_just_pressed("use_consumable"):
		use_consumable()


func use_consumable():
	remaining = max(remaining - 1, 0)
	if remaining > 0:
		return
	
	queue_free()

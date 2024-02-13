extends Node
class_name TriggerEvent

var player : Player
var target_node : Node2D


func setup(handler : EventHandlerComponent, new_target_node : Node2D):
	target_node = new_target_node


func trigger(new_player : Player):
	player = new_player


func reset():
	pass

extends Node
class_name TriggerEvent

var trigger_area : TriggerArea
var player : Player
var target_node : Node2D


func setup(new_trigger_area : TriggerArea, new_target_node : Node2D):
	trigger_area = new_trigger_area
	target_node = new_target_node


func trigger(new_player : Player):
	player = new_player


func reset():
	pass

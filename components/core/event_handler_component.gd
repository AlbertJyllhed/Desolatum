extends Node
class_name EventHandlerComponent

signal removed

@export var event_target : Node2D
@export var keep_on_trigger : bool = false

var events = []


func _ready():
	if get_child_count() == 0:
		push_error("EventHandlerComponent '%s': no events attached, removing the trigger" % get_path())
		queue_free()
		return
	
	events = get_children()
	for event in events:
		event.setup(self, event_target)


func trigger_events(body):
	for event in events:
		event.trigger(body)


func reset():
	for event in events:
		event.reset()
	
	if keep_on_trigger:
		return
	
	removed.emit()
	queue_free()

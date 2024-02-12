extends Node
class_name EventHandlerComponent

signal removed

@export var event_target : Node2D
@export var keep_on_trigger : bool = false

@export_group("Reset Timer Settings")
@export var timed_reset : bool = false
@export var reset_time : float = 1.0

@onready var reset_timer : Timer = $ResetTimer

var events = []


func _ready():
	if get_child_count() == 0:
		print("error, no events attached, removing trigger")
		queue_free()
		return
	
	events = get_children()
	for event in events:
		event.setup(self, event_target)


func trigger_events(body):
	for event in events:
		event.trigger(body)
	
	if not timed_reset:
		return
	
	reset_timer.start(reset_time)


func reset():
	for event in events:
		event.reset()
	
	if keep_on_trigger:
		return
	
	removed.emit()
	queue_free()


func _on_reset_timer_timeout():
	reset()

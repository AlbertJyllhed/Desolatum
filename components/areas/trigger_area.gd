extends Area2D
class_name TriggerArea

@onready var event_handler : EventHandlerComponent = $EventHandlerComponent


func _ready():
	event_handler.removed.connect(on_removed)


func _on_body_entered(body):
	event_handler.trigger_events(body)


func on_removed():
	queue_free()

extends Area2D
class_name TriggerArea

@onready var event_handler : EventHandlerComponent = $EventHandlerComponent


func _on_body_entered(body):
	event_handler.trigger_events(body)

extends Interactable

@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var event_handler_component : EventHandlerComponent = $EventHandlerComponent


func show_details():
	label.text = "Talk"


func interact():
	var player = get_tree().get_first_node_in_group("player")
	event_handler_component.trigger_events(player)
	collision_shape.set_deferred("disabled", true)

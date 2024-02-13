extends TriggerEvent

@export var reset_time : float = 1.0

@onready var timer : Timer = $Timer


func setup(handler : EventHandlerComponent, new_target_node : Node2D):
	super.setup(handler, new_target_node)
	timer.timeout.connect(handler.reset)


func trigger(new_player : Player):
	super.trigger(new_player)
	if not timer.is_stopped():
		return
	
	timer.start(reset_time)

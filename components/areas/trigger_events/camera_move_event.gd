extends TriggerEvent


func trigger(new_player : Player):
	super.trigger(new_player)
	GameEvents.set_camera_target.emit(target_node)


func reset():
	GameEvents.set_camera_target.emit(player)

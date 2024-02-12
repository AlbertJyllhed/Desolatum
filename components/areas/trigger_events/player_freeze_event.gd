extends TriggerEvent


func trigger(new_player : Player):
	super.trigger(new_player)
	player.set_active(false)


func reset():
	player.set_active(true)

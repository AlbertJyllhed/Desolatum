extends FiringComponent


func process_trigger(just_pressed: bool, _held: bool) -> void:
	if just_pressed and ready_to_shoot:
		fire()

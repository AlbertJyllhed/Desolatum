extends FiringComponent


func process_trigger(_just_pressed: bool, held: bool) -> void:
	if held and ready_to_shoot:
		fire()

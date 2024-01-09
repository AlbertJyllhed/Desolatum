extends FiringComponent


func _physics_process(_delta):
	if Input.is_action_pressed("attack"):
		if not ready_to_shoot:
			return
		
		fire()

extends AmmoComponent


func disable(value : bool):
	disabled = value
	if disabled:
		return
	
	GameEvents.ammo_updated.emit(ammo, max_ammo)


func use_ammo():
	if ammo == 0:
		return
	
	reload_timer.start(reload_time)
	decrement()
	has_ammo.emit()


func _on_reload_timer_timeout():
	ammo = min(ammo + 1, max_ammo)
	if ammo < max_ammo:
		reload_timer.start(reload_time)
	
	if not disabled:
		GameEvents.ammo_updated.emit(ammo, max_ammo)

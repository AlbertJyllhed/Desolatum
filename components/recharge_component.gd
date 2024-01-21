extends AmmoComponent


func _ready():
	ammo = max_ammo
	GameEvents.ammo_updated.emit(ammo, max_ammo)


func disable(value : bool):
	disabled = value
	if disabled:
		return
	
	GameEvents.ammo_updated.emit(ammo, max_ammo)


func use_ammo():
	if ammo == 0:
		return
	
	ammo = max(ammo - 1, 0)
	GameEvents.ammo_updated.emit(ammo, max_ammo)
	reload_timer.start(reload_time)
	has_ammo.emit()


func _on_reload_timer_timeout():
	ammo = min(ammo + 1, max_ammo)
	if ammo < max_ammo:
		reload_timer.start(reload_time)
	
	if not disabled:
		GameEvents.ammo_updated.emit(ammo, max_ammo)

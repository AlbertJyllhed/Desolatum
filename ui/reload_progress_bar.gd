extends TextureProgressBar

@export var ammo_component : AmmoComponent

var tween : Tween


func _ready():
	hide()
	if ammo_component:
		bind(ammo_component)


## Hooks the bar up to an ammo component (also used for ones created at runtime)
func bind(new_ammo_component : AmmoComponent) -> void:
	ammo_component = new_ammo_component
	ammo_component.reloading.connect(on_reload)
	ammo_component.cancel_reload.connect(reload_completed)


func on_reload(reload_time : float):
	if tween:
		tween.kill()
	
	show()
	value = 0
	tween = create_tween()
	tween.tween_property(self, "value", max_value, reload_time)
	tween.tween_callback(reload_completed)


func reload_completed():
	if tween:
		tween.kill()
	
	hide()
	value = 0

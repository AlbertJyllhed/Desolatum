extends Interactable
class_name Generator

@onready var sprite : Sprite2D = $Sprite2D

var time_ui_scene : PackedScene = preload("uid://cupc6eyn5o6xv")
var used : bool = false


func show_details():
	if used:
		return
	
	label.text = "start generator"


func interact():
	if used:
		return
	
	sprite.frame += 1
	used = true
	hide_details()
	GameEvents.start_wave.emit(1)
	
	var gui := get_tree().get_first_node_in_group("ui_layer") as GUI
	var time_ui_instance = time_ui_scene.instantiate() as TimeUI
	gui.add_to_hud(time_ui_instance)
	time_ui_instance.timer.timeout.connect(on_survived)


## The mission decides what finishing means (it unlocks the exit on complete).
func on_survived():
	GameEvents.objective_done.emit(self)

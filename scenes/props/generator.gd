extends Interactable
class_name Generator

@onready var sprite : Sprite2D = $Sprite2D

var time_ui_scene : PackedScene = preload("res://ui/time_ui.tscn")
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
	
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	var time_ui_instance = time_ui_scene.instantiate() as TimeUI
	ui_layer.add_child(time_ui_instance)
	time_ui_instance.timer.timeout.connect(unlock_exit)


func unlock_exit():
	GameEvents.unlock_exit.emit()

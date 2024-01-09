extends Interactable
class_name Generator

@onready var sprite : Sprite2D = $Sprite2D

var time_ui_scene : PackedScene = preload("res://ui/time_ui.tscn")
var stats : PlayerStats = preload("res://resources/Data/player_stats.tres")
var required_energy : int = 60
var used : bool = false


func show_details():
	if used:
		return
	
	label.text = str(required_energy) + " energy to start generator"


func interact():
	if used:
		return
	
	if stats.energy < required_energy:
		return
	
	stats.energy = max(stats.energy - required_energy, 0)
	GameEvents.energy_updated.emit(stats.energy)
	sprite.frame += 1
	
	used = true
	hide_details()
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	var time_ui_instance = time_ui_scene.instantiate() as TimeUI
	ui_layer.add_child(time_ui_instance)
	time_ui_instance.timer.timeout.connect(unlock_exit)


func unlock_exit():
	GameEvents.unlock_exit.emit()

extends Control
class_name UpgradeUI

signal open_teleporter

@onready var upgrades = $Upgrades
@onready var powering_screen = $PoweringScreen


func show_screen():
	show()
	get_tree().paused = true


func _on_close_button_pressed():
	hide()
	get_tree().paused = false


func _on_down_button_pressed():
	upgrades.visible = !upgrades.visible
	powering_screen.visible = !powering_screen.visible


func _on_powering_screen_fully_powered():
	open_teleporter.emit()
	hide()
	get_tree().paused = false

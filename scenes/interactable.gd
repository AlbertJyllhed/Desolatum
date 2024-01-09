extends StaticBody2D
class_name Interactable

@onready var label : Label = $Label


func show_details():
	label.text = "interactable"


func hide_details():
	label.text = ""


func interact():
	print("interacted")

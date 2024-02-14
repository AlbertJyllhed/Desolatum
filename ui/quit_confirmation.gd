extends Control

signal menu_closed


func _on_return_button_pressed():
	menu_closed.emit()
	hide()


func _on_quit_button_pressed():
	get_tree().quit()

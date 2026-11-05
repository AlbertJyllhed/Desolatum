extends Control

@onready var resume_button : Button = $NinePatchRect/CenterContainer/VBoxContainer/ResumeButton
@onready var return_button = $NinePatchRect/CenterContainer/VBoxContainer/ReturnButton
@onready var options_menu = $OptionsMenu
@onready var quit_confirmation = $QuitConfirmation

var paused : bool = false


func _ready():
	options_menu.menu_closed.connect(set_button_focus)
	quit_confirmation.menu_closed.connect(set_button_focus)
	# No point offering "Return to ship" while already on the ship.
	if owner and owner.scene_file_path == SceneManager.ship_scene.resource_path:
		return_button.hide()


func set_button_focus():
	resume_button.grab_focus()


func _input(event):
	if event.is_action_pressed("esc"):
		pause()


func pause():
	paused = !paused
	visible = paused
	get_tree().paused = paused
	
	options_menu.hide()
	quit_confirmation.hide()


func _on_resume_button_pressed():
	pause()


func _on_return_button_pressed():
	pause()
	SceneManager.travel_to_ship()


func _on_settings_button_pressed():
	options_menu.show()


func _on_quit_button_pressed():
	quit_confirmation.show()

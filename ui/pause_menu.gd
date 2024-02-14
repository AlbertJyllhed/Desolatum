extends Control

@onready var resume_button : Button = $NinePatchRect/CenterContainer/VBoxContainer/ResumeButton
@onready var return_button = $NinePatchRect/CenterContainer/VBoxContainer/ReturnButton
@onready var options_menu = $OptionsMenu
@onready var quit_confirmation = $QuitConfirmation

var paused : bool = false


func _ready():
	options_menu.menu_closed.connect(set_button_focus)
	quit_confirmation.menu_closed.connect(set_button_focus)
	var index = SceneManager.level_index
	if index == 0:
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
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	var transition_screen : TransitionScreen
	for child in ui_layer.get_children():
		if child is TransitionScreen:
			transition_screen = child
			break
	
	if not transition_screen:
		print("error: no transition screen")
		return
	
	transition_screen.fade_complete.connect(on_fade_complete)
	transition_screen.fade_to_black(true)


func on_fade_complete():
	SceneManager.load_level(0)


func _on_settings_button_pressed():
	options_menu.show()


func _on_quit_button_pressed():
	quit_confirmation.show()

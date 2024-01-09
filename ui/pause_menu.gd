extends Control

@onready var return_button = $NinePatchRect/CenterContainer/VBoxContainer/ReturnButton
@onready var quit_confirmation = $QuitConfirmation

var transition_screen_scene : PackedScene = preload("res://ui/transition_screen.tscn")
var paused : bool = false


func _ready():
	var index = SceneManager.level_index
	if index == 0:
		return_button.hide()


func _input(event):
	if event.is_action_pressed("esc"):
		pause()


func pause():
	paused = !paused
	visible = paused
	get_tree().paused = paused


func _on_resume_button_pressed():
	pause()


func _on_return_button_pressed():
	pause()
	var stats : PlayerStats = load("res://resources/Data/player_stats.tres")
	stats.reset()
	
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	var transition_screen_instance = transition_screen_scene.instantiate() as TransitionScreen
	ui_layer.add_child(transition_screen_instance)
	transition_screen_instance.fade_complete.connect(on_fade_complete)
	transition_screen_instance.fade(1)


func on_fade_complete():
	SceneManager.load_starting_level()


func _on_quit_button_pressed():
	quit_confirmation.show()

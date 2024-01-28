extends Control

@export var fps_counter : Control

@onready var resolution_button : OptionButton = $NinePatchRect/CenterContainer/VBoxContainer/ResolutionButton

var resolutions : Dictionary = {
	"3840x2160" : Vector2(3840, 2160),
	"2560x1440" : Vector2(2560, 1440),
	"1920x1080" : Vector2(1920, 1080),
	"1600x900" : Vector2(1600, 900),
	"1280x720" : Vector2(1280, 720)
}


func _ready():
	for resolution in resolutions:
		resolution_button.add_item(resolution)


func _on_close_button_pressed():
	hide()


func _on_resolution_button_item_selected(index):
	var size = resolutions.get(resolution_button.get_item_text(index))
	DisplayServer.window_set_size(size)


func _on_fullscreen_button_pressed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


func _on_windowed_button_pressed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	print(DisplayServer.window_get_size())


func _on_display_fps_button_toggled(toggled_on):
	fps_counter.visible = toggled_on

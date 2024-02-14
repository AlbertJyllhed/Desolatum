extends Control

signal menu_closed

@export var fps_counter : Control

@onready var resolution_button : OptionButton = $NinePatchRect/CenterContainer/VBoxContainer/ResolutionButton

var resolutions : Dictionary = {
	"16:9" : [Vector2i(320, 180), Vector2i(1280, 720)],
	"16:10" : [Vector2i(320, 200), Vector2i(1280, 800)],
	"4:3" : [Vector2i(320, 240), Vector2i(1280, 960)]
}

var current_resolution : Vector2i


func _ready():
	current_resolution = get_window().get_size()
	setup_resolutions()


func setup_resolutions():
	var current_content_size = get_window().get_content_scale_size()
	var id = 0
	
	for resolution in resolutions:
		resolution_button.add_item(resolution, id)
		if resolutions[resolution][0] == current_content_size:
			resolution_button.select(id)
		
		id += 1


func center_window():
	var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	get_window().set_position(screen_center - current_resolution / 2)


func _on_close_button_pressed():
	menu_closed.emit()
	hide()


func _on_resolution_button_item_selected(index):
	var size = resolutions.get(resolution_button.get_item_text(index))
	get_window().set_size(size[1])
	get_window().set_content_scale_size(size[0])
	current_resolution = get_window().get_size()
	
	var mode = get_window().mode
	if mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		get_window().set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)
		return
	
	center_window()


func _on_fullscreen_button_pressed():
	get_window().set_mode(Window.MODE_EXCLUSIVE_FULLSCREEN)


func _on_windowed_button_pressed():
	get_window().set_mode(Window.MODE_WINDOWED)
	get_window().set_size(current_resolution)
	center_window()


func _on_display_fps_button_toggled(toggled_on):
	fps_counter.visible = toggled_on

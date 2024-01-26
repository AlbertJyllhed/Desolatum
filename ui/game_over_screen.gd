extends Control

@onready var nine_patch_rect : NinePatchRect = $NinePatchRect
@onready var quit_confirmation = $QuitConfirmation

var load_index : int


func _ready():
	nine_patch_rect.position = Vector2(90, 200)
	var tween = get_tree().create_tween().bind_node(self)
	tween.tween_property($ColorRect, "color", Color(0, 0, 0, 125), 1)
	tween.tween_property(nine_patch_rect, "position", Vector2(90, 30), 2).set_trans(Tween.TRANS_QUINT)


func _on_restart_button_pressed():
	load_index = 1
	transition()


func _on_return_button_pressed():
	load_index = 0
	transition()


func transition():
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
	SceneManager.load_level(load_index)


func _on_quit_button_pressed():
	quit_confirmation.show()

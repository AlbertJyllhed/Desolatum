extends Control

@onready var nine_patch_rect : NinePatchRect = $NinePatchRect
@onready var quit_confirmation = $QuitConfirmation

var transition_screen_scene : PackedScene = preload("res://ui/transition_screen.tscn")


func _ready():
	nine_patch_rect.position = Vector2(90, 200)
	var tween = get_tree().create_tween().bind_node(self)
	tween.tween_property($ColorRect, "color", Color(0, 0, 0, 75), 1)
	tween.tween_property(nine_patch_rect, "position", Vector2(90, 30), 2).set_trans(Tween.TRANS_QUINT)


func _on_restart_button_pressed():
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	var transition_screen_instance = transition_screen_scene.instantiate() as TransitionScreen
	ui_layer.add_child(transition_screen_instance)
	transition_screen_instance.fade_complete.connect(on_fade_complete)
	transition_screen_instance.fade(1)


func on_fade_complete():
	SceneManager.load_starting_level()


func _on_quit_button_pressed():
	quit_confirmation.show()

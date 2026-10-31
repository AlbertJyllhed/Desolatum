extends Control

@onready var restart_button : Button = $NinePatchRect/CenterContainer/VBoxContainer/RestartButton
@onready var nine_patch_rect : NinePatchRect = $NinePatchRect
@onready var quit_confirmation = $QuitConfirmation

enum Levels {
	SHIP = 0,
	CAVE = 1,
}


func _ready():
	quit_confirmation.menu_closed.connect(set_button_focus)
	nine_patch_rect.position = Vector2(90, 200)
	var tween = get_tree().create_tween().bind_node(self)
	tween.tween_property($ColorRect, "color", Color(0, 0, 0, 125), 1)
	tween.tween_property(nine_patch_rect, "position", Vector2(90, 30), 2).set_trans(Tween.TRANS_QUINT)
	set_button_focus()


func set_button_focus():
	restart_button.grab_focus()


func _on_restart_button_pressed():
	SceneManager.change_level_with_fade(Levels.CAVE)


func _on_return_button_pressed():
	SceneManager.change_level_with_fade(Levels.SHIP)


func _on_quit_button_pressed():
	quit_confirmation.show()

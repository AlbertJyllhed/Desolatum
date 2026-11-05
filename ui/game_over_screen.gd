extends Control

@onready var restart_button : Button = $NinePatchRect/CenterContainer/VBoxContainer/RestartButton
@onready var nine_patch_rect : NinePatchRect = $NinePatchRect
@onready var color_rect : ColorRect = $ColorRect
@onready var quit_confirmation = $QuitConfirmation


func _ready():
	# The run is over: drop the autosave so quitting now and relaunching
	# can't bring the dead run back.
	SaveManager.delete_save()

	quit_confirmation.menu_closed.connect(set_button_focus)

	# Slide the panel up from below the screen into the centre.
	var viewport_size := get_viewport_rect().size
	var target := (viewport_size - nine_patch_rect.size) / 2.0
	nine_patch_rect.position = target + Vector2(0, viewport_size.y)

	var tween = get_tree().create_tween().bind_node(self)
	tween.tween_property(color_rect, "color", Color(0, 0, 0, 0.5), 1)
	tween.tween_property(nine_patch_rect, "position", target, 2).set_trans(Tween.TRANS_QUINT)
	set_button_focus()


func set_button_focus():
	restart_button.grab_focus()


## Quick retry: a fresh run, straight into its first level.
func _on_restart_button_pressed():
	SceneManager.start_new_run()


## Back to the hub with a fresh run; the hub teleporter starts the next one.
func _on_return_button_pressed():
	Run.new_run()
	SaveManager.save_game()
	SceneManager.travel_to_ship()


func _on_quit_button_pressed():
	quit_confirmation.show()

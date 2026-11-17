extends Menu

@onready var quit_confirmation : Menu = $QuitConfirmation


func _ready():
	super._ready()
	# The run is over: drop the autosave so quitting now and relaunching
	# can't bring the dead run back.
	SaveManager.delete_save()


## Quick retry: a fresh run, straight into its first level.
func _on_restart_button_pressed():
	SceneManager.start_new_run()


## Back to the hub with a fresh run; the hub teleporter starts the next one.
func _on_return_button_pressed():
	Run.new_run()
	SaveManager.save_game()
	SceneManager.travel_to_ship()


func _on_quit_button_pressed():
	open_sub_menu(quit_confirmation)

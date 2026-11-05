extends Control
class_name TransitionScreen

signal fade_complete()

@onready var animation_player : AnimationPlayer = $AnimationPlayer


func _ready():
	add_to_group("transition_screen")
	# Keep fading even if the game is paused (e.g. leaving from a menu).
	process_mode = Node.PROCESS_MODE_ALWAYS
	animation_player.animation_finished.connect(fade_completed)
	fade_to_black(false)


func fade_to_black(value : bool):
	if value:
		animation_player.play("fade_to_black")
		return
	
	animation_player.play("remove_fade")


func fade_completed(_animation : String):
	fade_complete.emit()

extends Control
class_name TransitionScreen

signal fade_complete()

@onready var animation_player : AnimationPlayer = $AnimationPlayer


func _ready():
	animation_player.animation_finished.connect(fade_completed)
	fade_to_black(false)


func fade_to_black(value : bool):
	if value:
		animation_player.play("fade_to_black")
		return
	
	animation_player.play("remove_fade")


func fade_completed(_animation : String):
	fade_complete.emit()

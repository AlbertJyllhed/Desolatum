extends Control
class_name TransitionScreen

signal fade_complete

@export var fade_on_ready : bool = false

@onready var color_rect : ColorRect = $ColorRect


func _ready():
	if not fade_on_ready:
		return
	
	color_rect.color = Color.BLACK
	fade(0)


func fade(value : int):
	var tween = get_tree().create_tween().bind_node(self)
	tween.tween_property($ColorRect, "color", Color(0, 0, 0, value), 1)
	tween.tween_callback(fade_completed)


func fade_completed():
	fade_complete.emit()
	queue_free()

extends Sprite2D

@export var shadow : Sprite2D
@export var min_frame : int = 0
@export var max_frame : int = 1


func _ready():
	frame = randi_range(min_frame, max_frame)
	if not shadow:
		return
	
	shadow.frame = frame

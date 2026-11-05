@icon("res://addons/at-icons/node/star.svg")
extends Node
class_name Mission

@export var title : String
@export_multiline var description : String

var completed : bool = false


## Called once the level has been generated.
func start(_level_generator : LevelGenerator) -> void:
	pass


func get_progress_text() -> String:
	return ""


func complete() -> void:
	if completed:
		return
	
	completed = true
	GameEvents.mission_completed.emit(self)
	GameEvents.unlock_exit.emit()

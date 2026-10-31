extends Node

var levels : Array[PackedScene] = [
	preload("res://levels/ship_hub.tscn"),
	preload("res://levels/main.tscn"),
	preload("res://levels/ice_level.tscn"),
	preload("res://levels/nest_level.tscn")
]

var level_index : int = 0:
	set(value):
		level_index = clampi(value, 0, levels.size() - 1)


func _ready():
	if not SaveManager.load_game():
		GameEvents.reset_stats.emit()


func load_level(index: int, new_run: bool = true) -> void:
	if new_run:
		Run.new_run() # fresh RunState, and it emits reset_stats itself
	level_index = index
	get_tree().change_scene_to_packed(levels[level_index])


func change_level_with_fade(index: int = -1, new_run: bool = true) -> void:
	var screen := get_tree().get_first_node_in_group("transition_screen") as TransitionScreen
	if screen == null:
		push_error("No node in the 'transition_screen' group")
		return
	screen.fade_to_black(true)
	await screen.fade_complete
	load_level(level_index + 1 if index < 0 else index, new_run)

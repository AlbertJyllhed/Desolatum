extends Node

var levels : Array[PackedScene] = [
	preload("res://ship_hub.tscn"),
	preload("res://main.tscn"),
	preload("res://ice_level.tscn"),
	preload("res://magma_level.tscn")
]

var max_level_index : int = 0
var level_index : int = 0


func _ready():
	max_level_index = levels.size() - 1


func load_starting_level():
	level_index = 0
	get_tree().change_scene_to_packed(levels[level_index])


func load_next_level():
	level_index = min(level_index + 1, max_level_index)
	get_tree().change_scene_to_packed(levels[level_index])

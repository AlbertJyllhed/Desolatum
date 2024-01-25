extends Node

var levels : Array[PackedScene] = [
	preload("res://levels/ship_hub.tscn"),
	preload("res://levels/main.tscn"),
	preload("res://levels/ice_level.tscn"),
	preload("res://levels/nest_level.tscn")
]

var max_level_index : int = 0
var level_index : int = 0


func _ready():
	max_level_index = levels.size() - 1


func load_level(index : int):
	clear_player_stats()
	level_index = index
	get_tree().change_scene_to_packed(levels[level_index])


func load_next_level():
	level_index = min(level_index + 1, max_level_index)
	get_tree().change_scene_to_packed(levels[level_index])


func clear_player_stats():
	var stats : PlayerStats = load("res://resources/Data/player_stats.tres")
	stats.reset()

extends Node

const SAVE_PATH = "user://save.json"

var player_stats : Resource = preload("res://resources/Data/player_stats.tres")

var global_position = Vector2.ZERO
var map_name = ""


func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var data = {
		"global_position" :
		{
			"x" : global_position.x,
			"y" : global_position.y
		},
		"map_name" : map_name,
		"player" : 
		{
			"health" : player_stats.health,
			"ammo" : player_stats.ammo,
			"speed" : player_stats.speed,
			"energy" : player_stats.energy
		}
	}
	
	var json_string = JSON.stringify(data)
	file.store_string(json_string)
	file.close()


func load_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var data : Dictionary = JSON.parse_string(content).result
	global_position = Vector2(data.global_position.x, data.global_position.y)
	map_name = data.map_name
	
	player_stats.health = data.health
	player_stats.ammo = data.ammo
	player_stats.speed = data.speed
	player_stats.energy = data.energy

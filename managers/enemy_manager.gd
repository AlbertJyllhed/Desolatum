extends Node
class_name EnemyManager

@export var enemy_list : EnemyList
@export var spawn_chance : float = 0.1

@onready var spawn_timer : Timer = $SpawnTimer
@onready var difficulty_timer : Timer = $DifficultyTimer

var difficulty_level : Dictionary = {
	"very_easy" : {
		"difficulty" : 8,
		"update_time" : 30.0
	},
	"easy" : {
		"difficulty" : 12,
		"update_time" : 60.0
	},
	"normal" : {
		"difficulty" : 16,
		"update_time" : 90.0
	},
	"hard" : {
		"difficulty" : 20,
		"update_time" : 120.0
	},
	"expert" : {
		"difficulty" : 24,
		"update_time" : 150.0
	}
}

var max_enemies : int
var index : int = 0

var spawners : Array[EnemySpawner]
var total_enemies : int = 0

var min_spawn_time : float = 10.0
var max_spawn_time : float = 15.0


func _ready():
	spawn_timer.timeout.connect(spawn)
	difficulty_timer.timeout.connect(update_difficulty)
	spawn_timer.start(randf_range(min_spawn_time, max_spawn_time))
	enemy_list.setup()
	update_difficulty()


func add_spawner(spawner : EnemySpawner):
	spawners.append(spawner)


func update_difficulty():
	spawn_chance = min(spawn_chance * 1.1, 1.0)
	var values = difficulty_level.values()
	max_enemies = values[index]["difficulty"]
	difficulty_timer.start(values[index]["update_time"])


func spawn():
	total_enemies = get_tree().get_nodes_in_group("enemies").size()
	for spawner in spawners:
		if total_enemies >= max_enemies:
			break
		
		if randf() > spawn_chance:
			continue
		
		var enemy_scene = enemy_list.spawn_table.pick_item()
		spawner.spawn_enemy(enemy_scene)
		total_enemies += 1
	
	spawn_timer.start(randf_range(min_spawn_time, max_spawn_time))
	index = min(index + 1, difficulty_level.size() - 1)

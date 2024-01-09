extends Node
class_name EnemyManager

@export var enemy_list : EnemyList
@export var max_enemies : int = 15
@export var spawn_chance : float = 0.6

@onready var timer : Timer = $Timer

var spawners : Array[EnemySpawner]
var total_enemies : int = 0
var spawn_time : float = 15.0


func _ready():
	timer.timeout.connect(spawn)
	timer.wait_time = spawn_time
	timer.start()
	enemy_list.setup()


func add_spawner(spawner : EnemySpawner):
	spawners.append(spawner)
	#spawner.ready.connect(on_spawner_ready.bind(spawner))


func on_spawner_ready(spawner : EnemySpawner):
	if randf() > spawn_chance:
		return
	
	var enemy_scene = enemy_list.spawn_table.pick_item()
	spawner.spawn_enemy(enemy_scene)


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

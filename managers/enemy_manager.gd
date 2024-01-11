extends Node
class_name EnemyManager

@export var enemy_list : EnemyList
@export var base_wave_time : float = 60.0

@onready var spawn_timer : Timer = $SpawnTimer
var spawn_time : float = 6.0

@onready var wave_timer : Timer = $WaveTimer
var wave_time : float

var spawners : Array[EnemySpawner]
var max_enemies : int
var spawn_modifier : float = 1.0

var wave_ongoing : bool = false


func _ready():
	GameEvents.health_updated.connect(adjust_spawn_rate)
	
	spawn_timer.timeout.connect(spawn)
	wave_timer.timeout.connect(update_difficulty)
	
	max_enemies = randi_range(1, 3)
	wave_time = base_wave_time
	
	enemy_list.setup()
	
	spawn_timer.start(spawn_time)
	wave_timer.start(wave_time)


func add_spawner(spawner : EnemySpawner):
	spawners.append(spawner)


func update_difficulty():
	var enemies = get_tree().get_nodes_in_group("enemies") as Array[EnemyEntity]
	if wave_ongoing:
		#end wave
		max_enemies = randi_range(4, 8) * spawn_modifier
		print("max enemies: " + str(max_enemies))
		wave_ongoing = false
		wave_time = base_wave_time
		for enemy in enemies:
			enemy.aggressive = false
		
		wave_timer.start(wave_time)
		print("wave ends")
		return
	
	#start wave, wave timer should be shorter than time between
	max_enemies = randi_range(24, 30) * spawn_modifier
	print("max enemies: " + str(max_enemies))
	wave_ongoing = true
	wave_time = base_wave_time / 2
	for enemy in enemies:
		enemy.aggressive = true
	
	wave_timer.start(wave_time)
	print("wave starts")


func adjust_spawn_rate(health, max_health):
	if health < (max_health / 2):
		spawn_modifier = 0.6
		return
	
	spawn_modifier = 1.0


func spawn():
	var total_enemies = get_tree().get_nodes_in_group("enemies").size()
	for spawner in spawners:
		if total_enemies >= max_enemies:
			break
		
		var spawn_chance = 0.3
		if randf() > spawn_chance:
			continue
		
		var enemy_scene = enemy_list.spawn_table.pick_item()
		spawner.spawn_enemy(enemy_scene, wave_ongoing)
		total_enemies += 1
	
	spawn_timer.start(spawn_time)

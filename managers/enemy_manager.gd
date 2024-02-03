extends Node
class_name EnemyManager

@export var enemy_list : EnemyList

@onready var spawn_timer : Timer = $SpawnTimer
var spawn_time : float

@onready var wave_timer : Timer = $WaveTimer
var wave_time : float

var wave_mode : Dictionary = {
	"buildup" : {
		"max_enemies" : 8,
		"spawn_time" : 10.0,
		"min_wave_time" : 60.0,
		"max_wave_time" : 120.0,
		"aggressive" : false
	},
	"action" : {
		"max_enemies" : 24,
		"spawn_time" : 4.0,
		"min_wave_time" : 30.0,
		"max_wave_time" : 60.0,
		"aggressive" : true
	},
	"cooldown" : {
		"max_enemies" : 3,
		"spawn_time" : 14.0,
		"min_wave_time" : 20.0,
		"max_wave_time" : 40.0,
		"aggressive" : false
	}
}

var index : int = 0

var spawners : Array[EnemySpawner]
var max_enemies : int
var spawn_aggressive : bool

var health_modifier : float = 1.0
var energy_modifier : float = 1.0


func _ready():
	GameEvents.start_wave.connect(set_difficulty)
	GameEvents.health_updated.connect(on_health_updated)
	GameEvents.energy_updated.connect(on_energy_updated)
	spawn_timer.timeout.connect(spawn)
	wave_timer.timeout.connect(update_difficulty)
	
	enemy_list.setup()
	
	update_difficulty()
	spawn_timer.start(spawn_time)


func add_spawner(spawner : EnemySpawner):
	spawners.append(spawner)


func update_difficulty():
	if index > (wave_mode.size() - 1):
		index = 0
	
	var enemies = get_tree().get_nodes_in_group("enemies") as Array[EnemyEntity]
	var values = wave_mode.values()
	max_enemies = values[index]["max_enemies"] * (energy_modifier * health_modifier)
	spawn_time = values[index]["spawn_time"]
	wave_time = randf_range(values[index]["min_wave_time"], values[index]["max_wave_time"])
	spawn_aggressive = values[index]["aggressive"]
	for enemy in enemies:
		enemy.aggressive = spawn_aggressive
	
	var keys = wave_mode.keys()
	print(keys[index])
	
	wave_timer.start(wave_time)
	GameEvents.wave_updated.emit(index)
	index += 1


func set_difficulty(new_index : int):
	index = new_index
	update_difficulty()


func on_health_updated(health, max_health):
	#health modifier lowers the max enemies based on player health
	health_modifier = max(health / max_health, 0.25)


func on_energy_updated(energy):
	#energy modifier raises the max enemies based on player energy
	var energy_percentage = float(energy) / 100
	energy_modifier = min(1.0 + energy_percentage, 1.5)


func spawn():
	var total_enemies = get_tree().get_nodes_in_group("enemies").size()
	var spawn_chance = 0.3
	for spawner in spawners:
		if total_enemies >= max_enemies:
			break
		
		if randf() > spawn_chance:
			continue
		
		var enemy_scene = enemy_list.spawn_table.pick_item()
		spawner.spawn_enemy(enemy_scene, spawn_aggressive)
		total_enemies += 1
	
	spawn_timer.start(spawn_time)

extends Resource
class_name EnemyList

@export var enemy_scenes : Array[PackedScene]
@export var weights : Array[int]

var spawn_table = WeightedTable.new()


func _init():
	GameEvents.reset_stats.connect(setup)
	call_deferred("setup")


func setup():
	spawn_table.reset()
	for i in enemy_scenes.size():
		spawn_table.add_item(enemy_scenes[i], weights[i])

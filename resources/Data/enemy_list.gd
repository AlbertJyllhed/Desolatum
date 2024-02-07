extends Resource
class_name EnemyList

@export var enemy_scenes : Array[PackedScene]
@export var weights : Array[int]

var spawn_table = WeightedTable.new()


func _init():
	call_deferred("setup")


func setup():
	for i in enemy_scenes.size():
		spawn_table.add_item(enemy_scenes[i], weights[i])

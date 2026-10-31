extends Resource
class_name DropList

var spawn_table = WeightedTable.new()
@export var items : Array[Item] = []


func _init():
	GameEvents.reset_stats.connect(setup)
	call_deferred("setup")


func setup():
	spawn_table.reset()
	for item in items:
		spawn_table.add_item(item, item.drop_weight, item.drop_limit)

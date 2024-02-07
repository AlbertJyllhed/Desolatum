extends Resource
class_name DropList

var spawn_table = WeightedTable.new()
@export var items : Array[Item] = []


func _init():
	call_deferred("setup")


func setup():
	#adds items for every resource!! array becomes way too big
	for item in items:
		spawn_table.add_item(item, item.drop_weight)

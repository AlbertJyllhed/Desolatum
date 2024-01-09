extends Resource
class_name DropList

var spawn_table = WeightedTable.new()
@export var items : Array[Item] = []


func setup():
	for item in items:
		spawn_table.add_item(item, item.drop_weight)

extends Resource
class_name PropList

@export var items: Array[PropItem] = []

var spawn_table = WeightedTable.new()


func _init() -> void:
	call_deferred("setup")


func setup():
	spawn_table.reset()
	for item in items:
		spawn_table.add_item(item, item.weight)

extends Resource
class_name DropList

var spawn_table = WeightedTable.new()
@export var items : Array[Item] = []


func setup():
	#adds items for every resource!! array becomes way too big
	for item in items:
		print(item.id)
		spawn_table.add_item(item, item.drop_weight)


func remove_item(item : Item):
	print("items left: " + str(spawn_table.items.size()))
	if spawn_table.items.size() == 1:
		return
	
	var item_to_erase : Dictionary
	for spawn_item in spawn_table.items:
		if spawn_item["item"] == item:
			item_to_erase = spawn_item
			print(item_to_erase["item"].id)
			break
	
	spawn_table.items.erase(item_to_erase)
	print("items left: " + str(spawn_table.items.size()))
	#for spawn_item in spawn_table.items:
		#print(spawn_item["item"].id)

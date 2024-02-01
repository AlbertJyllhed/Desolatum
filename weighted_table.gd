class_name WeightedTable

var items : Array[Dictionary] = []
var weight_sum = 0


func add_item(item, weight : int):
	for i in items:
		if i["item"] == item:
			return
	
	items.append({ "item" : item, "weight" : weight })
	weight_sum += weight


func pick_item():
	var chosen_weight = randi_range(1, weight_sum)
	var iteration_sum = 0
	for item in items:
		iteration_sum += item["weight"]
		if chosen_weight <= iteration_sum:
			return item["item"]


func remove_item(item_to_remove):
	if items.size() == 1:
		return
	
	for item in items:
		if item["item"] == item_to_remove:
			weight_sum -= item["weight"]
			items.erase(item)
			break

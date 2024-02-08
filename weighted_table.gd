class_name WeightedTable

var items : Array[Dictionary] = []
var weight_sum = 0


func add_item(item, weight : int, limit : int = -1):
	items.append({ "item" : item, "weight" : weight, "limit" : limit })
	weight_sum += weight


func pick_item():
	var chosen_weight = randi_range(1, weight_sum)
	var iteration_sum = 0
	for item in items:
		iteration_sum += item["weight"]
		if chosen_weight <= iteration_sum:
			return item["item"]


func adjust_weights(item_to_adjust):
	for item in items:
		if item["item"] != item_to_adjust:
			var rand_increase = randi_range(0, 1)
			item["weight"] += rand_increase
			weight_sum += rand_increase
			continue
		
		weight_sum -= item["weight"]
		item["weight"] = 1
		weight_sum += item["weight"]
		remove_item(item)


func remove_item(item_to_remove):
	if items.size() == 1 or item_to_remove["limit"] < 0:
		return
	
	item_to_remove["limit"] -= 1
	if item_to_remove["limit"] != 0:
		return
	
	weight_sum -= item_to_remove["weight"]
	items.erase(item_to_remove)


func reset():
	items.clear()
	weight_sum = 0

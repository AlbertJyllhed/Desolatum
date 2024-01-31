class_name Modifier

var add : int = 0
var mult : float = 1.0


func add_to_value(value, type : String):
	if type == "+":
		add += value
	if type == "*":
		mult += value


func get_values(base_stat):
	return (base_stat + add) * mult


func reset_values():
	add = 0
	mult = 1.0

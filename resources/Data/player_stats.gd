extends Resource
class_name PlayerStats

@export var base_health : int = 6
@export var base_move_speed : float = 80.0

var player_stats : Dictionary = {
	"max_health" : 6,
	"health" : 6,
	"move_speed" : 80.0
}

#test implementation of new modifiers
var test : Dictionary = {
	"health" : null,
	"move_speed" : null,
	"damage" : null,
	"bullet_speed" : null,
	"bullet_spread" : null,
	"ammo" : null,
	"reload_speed" : null,
	"firing_speed" : null,
	"crit_chance" : null
}

var modifiers : Dictionary = {
	"health" : [0, 1.0],
	"move_speed" : [0, 1.0],
	"damage" : [0, 1.0],
	"bullet_speed" : [0, 1.0],
	"bullet_spread" : [0, 1.0],
	"ammo" : [0, 1.0],
	"reload_speed" : [0, 1.0],
	"firing_speed" : [0, 1.0],
	"crit_chance" : [0, 1.0]
}

@export var starter_equipment : Array[EquipmentItem]
var equipment : Array[EquipmentItem]

var active_item : EquipmentItem
var consumable : EquipmentItem

var energy : int = 0
var ore : int = 0


func _init():
	for key in test.keys():
		test[key] = Modifier.new()
	
	call_deferred("reset")


func add_modifiers(mods : Dictionary, type : String):
	#add to or remove from the current multipliers
	#send out the multipliers to the relevant nodes
	for mod in mods:
		test[mod].add_to_value(mods[mod], type)
		print(test[mod].mult)
	
	for mod in mods:
		if type == "+":
			modifiers[mod][0] += mods[mod]
		if type == "*":
			modifiers[mod][1] += mods[mod]
	
	GameEvents.stats_changed.emit(test)
	#GameEvents.stats_changed.emit(modifiers)
	#print(modifiers)


func update_stats():
	GameEvents.stats_changed.emit(test)
	#GameEvents.stats_changed.emit(modifiers)


func reset():
	player_stats["max_health"] = base_health
	player_stats["health"] = base_health
	player_stats["move_speed"] = base_move_speed
	
	for key in modifiers:
		modifiers[key][0] = 0
		modifiers[key][1] = 1.0
	
	for mod in test:
		test[mod].reset_values()
	
	equipment = starter_equipment.duplicate()
	#for item in equipment:
		#print(item.name)
	
	energy = 0
	ore = 0

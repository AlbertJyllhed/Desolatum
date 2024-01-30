extends Resource
class_name PlayerStats

@export var base_health : int = 6
@export var base_move_speed : float = 80.0

var player_stats : Dictionary = {
	"max_health" : 6,
	"health" : 6,
	"move_speed" : 80.0
}

var modifiers : Dictionary = {
	"health" : [0, 1.0],
	"move_speed" : [0, 1.0],
	"damage" : [0, 1.0],
	"bullet_speed" : [0, 1.0],
	"bullet_spread" : [0, 1.0],
	"ammo" : [0, 1.0],
	"reload_speed" : [0, 1.0],
	"firing_speed" : [0, 1.0]
}

@export var starter_equipment : Array[EquipmentItem]
var equipment : Array[EquipmentItem]

var active_item : EquipmentItem
var consumable : EquipmentItem

var energy : int = 0
var ore : int = 0


func _init():
	call_deferred("reset")


func add_modifiers(mods : Dictionary, type : String):
	#add to or remove from the current multipliers
	#send out the multipliers to the relevant nodes
	for mod in mods:
		if type == "+":
			modifiers[mod][0] += mods[mod]
		if type == "*":
			modifiers[mod][1] += mods[mod]
	
	GameEvents.stats_changed.emit(modifiers)
	#print(modifiers)


func update_stats():
	GameEvents.stats_changed.emit(modifiers)


func reset():
	player_stats["max_health"] = base_health
	player_stats["health"] = base_health
	player_stats["move_speed"] = base_move_speed
	
	for key in modifiers:
		modifiers[key][0] = 0
		modifiers[key][1] = 1.0
	
	equipment = starter_equipment.duplicate()
	#for item in equipment:
		#print(item.name)
	
	energy = 0
	ore = 0

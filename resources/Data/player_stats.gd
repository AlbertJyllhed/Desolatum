extends Resource
class_name PlayerStats

@export var base_health : int = 6
@export var base_speed : float = 80.0

var stats : Dictionary = {
	"health" : {
		"base" : 6,
		"current" : 6,
		"mod" : 1.0
	},
	"move_speed" : {
		"base" : 80.0,
		"current" : 80.0,
		"mod" : 1.0
	},
	"damage" : {
		"mod" : 1.0
	},
	"ammo" : {
		"mod" : 1.0
	},
	"reload_speed" : {
		"mod" : 1.0
	},
	"bullet_speed" : {
		"mod" : 1.0
	},
	"bullet_spread" : {
		"mod" : 1.0
	}
}

@export var starter_equipment : Array[EquipmentItem]
var equipment : Array[EquipmentItem]

var active_item : EquipmentItem
var consumable : EquipmentItem

var energy : int = 0
var ore : int = 0


func _init():
	call_deferred("reset")


func add_to_multiplier(id, amount):
	#add to or remove from the current multipliers
	#send out the multipliers to the relevant nodes
	for key in stats.keys():
		if key == id:
			stats[key]["mod"] += amount
			print(stats[key])
	
	GameEvents.stats_changed.emit(stats)


func update_equipment(weapon : PlayerWeaponBase):
	#change the stats here based on the new weapons stats
	#send back the weapon modifiers to the new weapon
	print("equipment updated: " + weapon.name)
	
	GameEvents.stats_changed.emit(stats)


func reset():
	stats["health"]["base"] = base_health
	stats["health"]["current"] = base_health
	stats["move_speed"]["current"] = base_speed
	for key in stats.keys():
		stats[key]["mod"] = 1.0
	equipment = starter_equipment.duplicate()
	#for item in equipment:
		#print(item.name)
	energy = 0
	ore = 0

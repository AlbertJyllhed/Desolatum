extends Resource
class_name PlayerStats

@export var base_health : int = 6
@export var base_move_speed : float = 80.0

var player_stats : Dictionary = {
	"max_health" : 6,
	"health" : 6,
	"move_speed" : 80.0
}

var stat_list : Array[String] = [
	"health",
	"move_speed",
	"damage",
	"bullet_speed",
	"bullet_spread",
	"ammo",
	"reload_speed",
	"firing_speed",
	"crit_chance",
	"explode_chance"
]

var modifiers : Dictionary = {}
var upgrades : Array[UpgradeItem]

@export var starter_equipment : Array[EquipmentItem]
var equipment : Array[EquipmentItem]

var active_item : EquipmentItem
var consumable : EquipmentItem

var energy : int = 0
var ore : int = 0


func _init():
	for stat in stat_list:
		modifiers[stat] = Modifier.new()
	
	GameEvents.item_picked_up.connect(on_item_picked_up)
	call_deferred("reset")


func add_modifiers(mods : Dictionary, type : String):
	#add to or remove from the current multipliers
	#send out the multipliers to the relevant nodes
	for mod in mods:
		modifiers[mod].add_to_value(mods[mod], type)
		#print(modifiers[mod].add)
	
	GameEvents.stats_changed.emit(modifiers)


func update_stats():
	GameEvents.stats_changed.emit(modifiers)


func on_item_picked_up(item : Item):
	if not item is UpgradeItem:
		return
	
	upgrades.append(item)
	for upgrade in upgrades:
		print(upgrade.id)


func add_upgrades():
	if upgrades.size() == 0:
		return
	
	for upgrade in upgrades:
		GameEvents.add_upgrade.emit(upgrade)


func reset():
	player_stats["max_health"] = base_health
	player_stats["health"] = base_health
	player_stats["move_speed"] = base_move_speed
	
	for mod in modifiers:
		modifiers[mod].reset_values()
	
	upgrades.clear()
	equipment = starter_equipment.duplicate()
	#for item in equipment:
		#print(item.name)
	
	energy = 0
	ore = 0

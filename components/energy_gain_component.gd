extends Node
class_name EnergyGainComponent

var stats : PlayerStats


func setup(new_stats : PlayerStats):
	stats = new_stats
	stats.energy = 0
	stats.ore = 0
	GameEvents.energy_updated.emit(stats.energy)
	GameEvents.ore_updated.emit(stats.ore)
	GameEvents.item_picked_up.connect(on_item_picked_up)


func on_item_picked_up(item : Item):
	if item.id == "energy":
		stats.energy += item.amount
		GameEvents.energy_updated.emit(stats.energy)
	
	if item.id == "ore":
		stats.ore += item.amount
		GameEvents.ore_updated.emit(stats.ore)

@icon("res://addons/at-icons/node/lightning_bolt.svg")
extends Node
class_name EnergyGainComponent


func setup():
	GameEvents.energy_updated.emit(Run.state.energy)
	GameEvents.ore_updated.emit(Run.state.ore)
	GameEvents.item_picked_up.connect(on_item_picked_up)


func on_item_picked_up(item : Item):
	if item.id == "energy":
		Run.state.energy += item.amount
	
	if item.id == "ore":
		Run.state.ore += item.amount

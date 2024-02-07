extends InventoryComponent
class_name WeaponInventoryComponent

signal weapon_replaced()

@onready var audio_stream_player : AudioStreamPlayer2D = $AudioStreamPlayer2D

var stats : PlayerStats
var ability : Ability
var consumable : Consumable

var base_layer : Node2D
var pickup_scene : PackedScene = preload("res://scenes/pickups/pickup.tscn")


func setup(new_stats : PlayerStats):
	stats = new_stats
	weapon_replaced.connect(stats.update_stats)
	base_layer = get_tree().get_first_node_in_group("base_layer")
	GameEvents.item_picked_up.connect(on_item_picked_up)
	
	#if the player had equipped weapons in the previous scene we add them
	if stats.equipment.size() > 0:
		for item in stats.equipment:
			add_item(item)
	
	if stats.ability_item: add_ability(stats.ability_item)
	if stats.consumable: add_consumable(stats.consumable)


func equip_weapon(weapon_index):
	#hide all weapons and then show the active one
	for item in items:
		item.disable(true)
	
	items[weapon_index].disable(false)
	GameEvents.weapons_updated.emit(weapon_index)


func next_slot():
	if index == max_index:
		return
	
	super.next_slot()
	audio_stream_player.play()
	equip_weapon(index)


func prev_slot():
	if index == 0:
		return
	
	super.prev_slot()
	audio_stream_player.play()
	equip_weapon(index)


func add_item(new_item : Item):
	#GameEvents.weapons_updated.emit(new_item)
	
	var weapon = create_equipment_instance(new_item)
	
	if items.size() == stats.equipment.size():
		for item in stats.equipment:
			if new_item.type == item.type:
				index = item.type
		
		create_pickup(stats.equipment[index])
		items.pop_at(index).queue_free()
		items.insert(index, weapon)
		stats.equipment[index] = new_item
	else:
		items.append(weapon)
	
	max_index = items.size() - 1
	index = 0
	equip_weapon(index)
	weapon_replaced.emit()


func add_ability(new_item : Item):
	if ability: ability.queue_free()
	ability = create_equipment_instance(new_item)


func add_consumable(new_item : Item):
	if consumable:
		if consumable.item == new_item:
			consumable.add_item(new_item)
			return
		
		create_pickup(consumable.item)
		consumable.queue_free()
	
	consumable = create_equipment_instance(new_item)
	var player = get_parent() as Player
	consumable.setup(player, new_item)
	stats.consumable = consumable.item
	consumable.used.connect(on_consumable_used)


func on_consumable_used():
	consumable = null
	stats.consumable = null


func create_pickup(new_item : Item):
	#create pickup from current gun and drop it to the ground
	var pickup_instance = pickup_scene.instantiate()
	base_layer.add_child(pickup_instance)
	pickup_instance.set_item(new_item)
	pickup_instance.global_position = global_position


func create_equipment_instance(new_item : Item):
	#instantiate the new weapon and add it as a child of the inventory
	var weapon = new_item.equipment_scene.instantiate()
	add_child(weapon)
	var offset = Vector2(0, -4)
	weapon.global_position = global_position + offset
	return weapon


func on_item_picked_up(item : Item):
	#equip a new weapon when its picked up
	if not item is EquipmentItem:
		return
	
	if item.type == item.EquipmentType.ability:
		add_ability(item)
		return
	
	if item.type == item.EquipmentType.consumable:
		add_consumable(item)
		return
	
	add_item(item)

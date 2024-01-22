extends InventoryComponent
class_name WeaponInventoryComponent

signal weapon_replaced(weapon)

@export var starter_items : Array[Item]

@onready var audio_stream_player : AudioStreamPlayer2D = $AudioStreamPlayer2D

var stats : PlayerStats = preload("res://resources/Data/player_stats.tres")

var base_layer : Node2D
var pickup_scene : PackedScene = preload("res://scenes/pickups/pickup.tscn")


func _ready():
	base_layer = get_tree().get_first_node_in_group("base_layer")
	GameEvents.item_picked_up.connect(on_item_picked_up)
	
	#if the player had equipped weapons in the previous scene we add them
	if stats.equipment.size() > 0:
		for item in stats.equipment:
			add_item(item)
	else:
		for item in starter_items:
			add_item(item)


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
	
	var weapon = create_weapon_instance(new_item)
	
	if items.size() == starter_items.size():
		for item in starter_items:
			if new_item.type == item.type:
				index = item.type
		
		create_pickup()
		items.insert(index, weapon)
		stats.equipment[index] = new_item
		starter_items[index] = new_item
		weapon_replaced.emit(items[index])
	else:
		items.append(weapon)
		stats.equipment.assign(starter_items)
	
	max_index = items.size() - 1
	index = 0
	equip_weapon(index)


func create_pickup():
	#create pickup from current gun and drop it to the ground
	var pickup_instance = pickup_scene.instantiate()
	base_layer.add_child(pickup_instance)
	pickup_instance.set_item(starter_items[index])
	pickup_instance.global_position = global_position
	items.pop_at(index).queue_free()


func create_weapon_instance(new_item : Item):
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
	
	add_item(item)

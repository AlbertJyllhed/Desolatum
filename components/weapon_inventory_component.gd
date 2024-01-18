extends InventoryComponent

@export var weapon_items : Array[Item]

@onready var audio_stream_player : AudioStreamPlayer2D = $AudioStreamPlayer2D

var stats : PlayerStats = preload("res://resources/Data/player_stats.tres")

var base_layer : Node2D
var pickup_scene : PackedScene = preload("res://scenes/pickups/pickup.tscn")


func _ready():
	base_layer = get_tree().get_first_node_in_group("base_layer")
	GameEvents.item_picked_up.connect(on_item_picked_up)
	
	#if the player had equipped weapons in the previous scene we add them
	if stats.weapons.size() > 0:
		for item in stats.weapons:
			add_item(item)
	else:
		for item in weapon_items:
			add_item(item)
	
	index = stats.equipment_index
	equip_weapon(index)


func equip_weapon(weapon_index):
	#hide all weapons and then show the active one
	for item in items:
		item.hide()
		item.disable(true)
	
	items[weapon_index].disable(false)
	items[weapon_index].show()
	GameEvents.weapons_updated.emit(weapon_index)


func deactivate(value : bool):
	deactivated = value
	if deactivated:
		hide()
		items[index].disable(true)
		return
	
	show()
	items[index].disable(false)


func next_slot():
	if index == max_index:
		return
	
	super.next_slot()
	stats.equipment_index = index
	audio_stream_player.play()
	equip_weapon(index)


func prev_slot():
	if index == 0:
		return
	
	super.prev_slot()
	stats.equipment_index = index
	audio_stream_player.play()
	equip_weapon(index)


func add_item(new_item : Item):
	#GameEvents.weapons_updated.emit(new_item)
	
	if items.size() > 1:
		if new_item.type == new_item.WeaponType.gun:
			var pickup_instance = create_pickup()
			var weapon = create_weapon_instance(new_item)
			items.push_front(weapon)
			stats.weapons[0] = new_item
			weapon_items[0] = new_item
	else:
		var weapon = create_weapon_instance(new_item)
		items.append(weapon)
		stats.weapons.append(new_item)
	
	max_index = items.size() - 1
	index = 0
	equip_weapon(index)


func create_pickup():
	#create pickup from current gun and drop it to the ground
	var pickup_instance = pickup_scene.instantiate()
	base_layer.add_child(pickup_instance)
	pickup_instance.set_item(weapon_items[0])
	pickup_instance.global_position = global_position
	items[0].queue_free()
	items.remove_at(0)


func create_weapon_instance(new_item : Item):
	#instantiate the new weapon and add it as a child of the inventory
	var weapon = new_item.weapon_scene.instantiate()
	add_child(weapon)
	var offset = Vector2(0, -4)
	weapon.global_position = global_position + offset
	return weapon


func on_item_picked_up(item : Item):
	#equip a new weapon when its picked up
	if not item is WeaponItem:
		return
	
	stats.equipment_index = 0
	add_item(item)

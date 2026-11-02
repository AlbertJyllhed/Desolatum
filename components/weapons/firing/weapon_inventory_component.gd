extends InventoryComponent
class_name WeaponInventoryComponent

signal weapon_replaced

@onready var audio_stream_player : AudioStreamPlayer2D = $AudioStreamPlayer2D

var consumable : Consumable
var base_layer : Node2D


func setup():
	weapon_replaced.connect(Run.state.update_stats)
	base_layer = get_tree().get_first_node_in_group("base_layer")
	GameEvents.item_picked_up.connect(on_item_picked_up)
	
	#if the player had equipped weapons in the previous scene we add them
	if Run.state.equipment.size() > 0:
		for item in Run.state.equipment:
			add_item(item)
	
	if Run.state.consumable: add_consumable(Run.state.consumable)


func equip_weapon(weapon_index):
	#hide all weapons and then show the active one
	for item in items:
		item.disable(true)
	
	if deactivated:
		return # suspended (e.g. build mode), keep everything disabled
	
	items[weapon_index].disable(false)
	GameEvents.weapons_updated.emit(weapon_index)


func next_slot():
	if deactivated or index == max_index:
		return
	
	super.next_slot()
	audio_stream_player.play()
	equip_weapon(index)


func prev_slot():
	if deactivated or index == 0:
		return
	
	super.prev_slot()
	audio_stream_player.play()
	equip_weapon(index)


func add_item(new_item : Item):
	var weapon = create_equipment_instance(new_item)
	
	if items.size() == Run.state.equipment.size():
		for item in Run.state.equipment:
			if new_item.type == item.type:
				index = item.type
		
		create_pickup(Run.state.equipment[index])
		items.pop_at(index).queue_free()
		items.insert(index, weapon)
		Run.state.equipment[index] = new_item
	else:
		items.append(weapon)
	
	max_index = items.size() - 1
	index = 0
	equip_weapon(index)
	weapon_replaced.emit()


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
	Run.state.consumable = consumable.item
	consumable.used.connect(on_consumable_used)


func on_consumable_used():
	consumable = null
	Run.state.consumable = null


func create_pickup(new_item : Item):
	#create pickup from current gun and drop it to the ground
	var pickup_instance = Scenes.PICKUP.instantiate()
	base_layer.add_child(pickup_instance)
	pickup_instance.set_item(new_item)
	pickup_instance.global_position = global_position


func create_equipment_instance(new_item : Item):
	#instantiate the new weapon and add it as a child of the inventory
	var weapon = new_item.equipment_scene.instantiate()
	add_child(weapon)
	weapon.global_position = global_position
	return weapon


func set_suspended(value: bool):
	deactivate(value) # hides the weapons and blocks scroll switching
	if value:
		for item in items:
			item.disable(true) # stops firing/reloading
	else:
		equip_weapon(index) # re-enables only the active weapon


func on_item_picked_up(item : Item):
	#equip a new weapon when its picked up
	if not item is EquipmentItem:
		return
	
	if item.type == item.EquipmentType.consumable:
		add_consumable(item)
		return
	
	add_item(item)

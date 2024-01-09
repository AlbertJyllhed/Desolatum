extends Node

@export var min_drop_amount : int = 1
@export var max_drop_amount : int = 1
@export var drop_chance : float = 1.0
@export var health_component : Node

@export var drop_list : DropList
var drop_amount

var pickup : PackedScene = preload("res://scenes/pickups/pickup.tscn")
var auto_pickup : PackedScene = preload("res://scenes/pickups/auto_pickup.tscn")


func _ready():
	drop_list.setup()
	drop_amount = randi_range(min_drop_amount, max_drop_amount)
	if not health_component:
		return
	
	(health_component as HealthComponent).died.connect(on_died)


func on_died():
	if not owner is Node2D:
		return
	
	for i in drop_amount:
		var rand = randf()
		if rand > drop_chance:
			continue
		
		var item = drop_list.spawn_table.pick_item() as Item
		var instance : Node2D
		if item.pickup_type == item.PickupType.auto:
			instance = auto_pickup.instantiate() as Node2D
		else:
			instance = pickup.instantiate() as Node2D
		
		instance.set_item(item)
		
		var offset = Vector2(randf_range(-8, 8), randf_range(-8, 8))
		var spawn_position = (owner as Node2D).global_position + offset
		var base_layer = get_tree().get_first_node_in_group("base_layer")
		base_layer.add_child(instance)
		instance.global_position = spawn_position

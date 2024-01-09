extends Node2D

@export var amount : int = 3

var base_layer : Node2D
var tether_scene : PackedScene = preload("res://components/tether_node.tscn")

var tethers : Array[TetherNode]
var current_tether : TetherNode


func _ready():
	base_layer = get_tree().get_first_node_in_group("base_layer")
	GameEvents.item_picked_up.connect(on_item_picked_up)


func _physics_process(delta):
	if Input.is_action_just_pressed("alt_attack") and amount > 0:
		place_tether()


func place_tether():
	var tether_instance = tether_scene.instantiate() as TetherNode
	base_layer.add_child(tether_instance)
	tether_instance.global_position = global_position
	if current_tether:
		current_tether.player = null
	
	tethers.append(tether_instance)
	current_tether = tethers.back()
	current_tether.player = owner as Player
	amount = max(amount - 1, 0)


func is_active() -> bool:
	return false


func on_item_picked_up(item : Item):
	if item.id != "tether":
		return
	
	amount += item.amount
	tethers.erase(current_tether)
	if tethers.size() == 0:
		current_tether = null
		return
	
	current_tether = tethers.back()
	current_tether.player = owner as Player

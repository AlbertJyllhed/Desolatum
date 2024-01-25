extends Node2D
class_name BuildIndicator

@export var building_scene : PackedScene
@export var limit : int = 1
@export var recharge_time : float = 30.0

@onready var tile_checker_area : Area2D = $TileCheckerArea
@onready var timer : Timer = $Timer

var tilemap : TileMap
var base_layer : Node2D

var placed_amount : int
var disabled : bool = false


func _ready():
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")


func can_place() -> bool:
	if tile_checker_area.has_overlapping_bodies() or placed_amount >= limit:
		modulate = Color.RED
		modulate.a = 0.5
		return false
	
	modulate = Color.GREEN
	modulate.a = 0.5
	return true


func _physics_process(_delta):
	if disabled:
		return
	
	var mouse_tile = tilemap.local_to_map(get_global_mouse_position())
	var local_pos = tilemap.map_to_local(mouse_tile)
	var global_pos = tilemap.to_global(local_pos)
	var offset = Vector2(8, 8)
	global_position = global_pos - offset
	
	if not can_place():
		return
	
	if Input.is_action_just_pressed("attack"):
		place_building(global_pos)


func place_building(pos : Vector2):
	var building_instance = building_scene.instantiate()
	base_layer.add_child(building_instance)
	building_instance.global_position = pos
	placed_amount = min(placed_amount + 1, limit)
	timer.start(recharge_time)


func disable(value : bool):
	disabled = value
	visible = !value


func _on_timer_timeout():
	placed_amount = 0

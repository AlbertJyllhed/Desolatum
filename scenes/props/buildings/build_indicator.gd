extends Node2D
class_name BuildIndicator

@export var building_scene : PackedScene

@onready var sprite : Sprite2D = $BuildingSprite
@onready var tile_checker_area : Area2D = $TileCheckerArea
@onready var collision_shape : CollisionShape2D = $TileCheckerArea/CollisionShape2D

var tilemap : TileMap
var base_layer : Node2D


func _ready():
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")


func can_place() -> bool:
	if tile_checker_area.has_overlapping_bodies():
		modulate = Color.RED
		modulate.a = 0.5
		return false
	
	modulate = Color.GREEN
	modulate.a = 0.5
	return true


func _physics_process(_delta):
	var mouse_tile = tilemap.local_to_map(get_global_mouse_position())
	var local_pos = tilemap.map_to_local(mouse_tile)
	var global_pos = tilemap.to_global(local_pos)
	var offset = Vector2(8, 8)
	global_position = global_pos - offset
	
	if not can_place():
		return
	
	if Input.is_action_just_pressed("attack"):
		var building_instance = building_scene.instantiate()
		base_layer.add_child(building_instance)
		building_instance.global_position = global_pos

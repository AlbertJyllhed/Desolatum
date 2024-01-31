extends Ability

@export var ability_scene : PackedScene

@onready var tile_checker_area : Area2D = $TileCheckerArea

var tilemap : TileMap
var base_layer : Node2D


func _ready():
	super._ready()
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")


func try_use_ability():
	if tile_checker_area.has_overlapping_bodies():
		return
	
	super.try_use_ability()


func use_ability():
	var mouse_tile = tilemap.local_to_map(get_global_mouse_position())
	var local_pos = tilemap.map_to_local(mouse_tile)
	var global_pos = tilemap.to_global(local_pos)
	var offset = Vector2(8, 8)
	global_position = global_pos - offset
	
	var ability_instance = ability_scene.instantiate()
	base_layer.add_child(ability_instance)
	ability_instance.global_position = global_pos
	super.use_ability()

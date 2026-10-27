extends Area2D

@export var remove_by_position : bool = false

@onready var collision_shape : CollisionShape2D = $CollisionShape2D

var tilemap : TileMap
var auto_pickup : PackedScene = preload("res://scenes/pickups/auto_pickup.tscn")
var energy : Item = preload("res://resources/Items/energy.tres")
var ore : Item = preload("res://resources/Items/ore.tres")
enum { ground = 0, ceiling = 1, wall = 2, bedrock = 3, shadow = 14, none = -1 }


func _ready():
	if not remove_by_position:
		return
	
	var map = get_tree().get_first_node_in_group("tilemap_layer") as TileMap
	if not map:
		return
	
	var circle = collision_shape.shape as CircleShape2D
	var radius_in_tiles = circle.radius / 16.0 if circle else 1.0
	var center = map.local_to_map(map.to_local(global_position))
	var r = ceili(radius_in_tiles)
	for x in range(-r, r + 1):
		for y in range(-r, r + 1):
			if Vector2(x, y).length() > radius_in_tiles:
				continue
			
			remove_tile(map, center + Vector2i(x, y))


func remove_tile(map : TileMap, coordinate : Vector2i):
	tilemap = map
	var tile_id = tilemap.get_cell_source_id(0, coordinate)
	if tile_id != wall and tile_id != ceiling:
		return
	
	var tile_data = tilemap.get_cell_tile_data(0, coordinate)
	var random_tile = Vector2i(randi_range(0, 2), 0)
	tilemap.set_cell(0, coordinate, ground, random_tile)
	tilemap.set_cell(1, coordinate, none, Vector2i.ZERO)
	update_neighbors(coordinate)
	GameEvents.navigation_updated.emit(coordinate, false)
	create_ore(coordinate, tile_data)


func update_neighbors(coordinate):
	#remove shadow below the destroyed tile
	var bottom_tile = tilemap.get_neighbor_cell(coordinate, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
	var bottom_tile_id = tilemap.get_cell_source_id(0, bottom_tile)
	
	if bottom_tile_id == wall:
		var bottom_atlas_coords = tilemap.get_cell_atlas_coords(0, bottom_tile)
		tilemap.set_cell(1, bottom_tile, ceiling, Vector2i(bottom_atlas_coords.x, 1))
	else:
		tilemap.set_cell(1, bottom_tile, none, Vector2i.ZERO)
	
	#add new wall above the destroyed tile if there is a ceiling there
	var top_tile = tilemap.get_neighbor_cell(coordinate, TileSet.CELL_NEIGHBOR_TOP_SIDE)
	var top_tile_id = tilemap.get_cell_source_id(0, top_tile)
	
	if top_tile_id == ceiling:
		var top_atlas_coords = tilemap.get_cell_atlas_coords(0, top_tile)
		tilemap.set_cell(0, top_tile, wall, top_atlas_coords)
		tilemap.set_cell(1, top_tile, ceiling, Vector2i(top_atlas_coords.x, 1))
		#add a shadow on top of the destroyed tile
		tilemap.set_cell(1, coordinate, shadow, Vector2i.ZERO)


func create_ore(tile_position, tile_data):
	var ore_type = tile_data.get_custom_data("ore_type")
	if ore_type == 0:
		return
	
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	var pickup_instance = auto_pickup.instantiate() as AutoPickup
	base_layer.call_deferred("add_child", pickup_instance)
		
	if ore_type == 1:
		pickup_instance.set_item(energy)
	elif ore_type == 2:
		pickup_instance.set_item(ore)
		
	var offset = Vector2i(8, 8)
	pickup_instance.global_position = (tile_position * 16) + offset

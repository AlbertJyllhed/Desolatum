extends Node
class_name LevelGenerator

const player_scene = preload("res://characters/player.tscn")
const teleporter_scene = preload("res://scenes/props/teleport_platform.tscn")
const generator_scene = preload("res://scenes/props/generator.tscn")
const spawner_scene = preload("res://enemy_spawner.tscn")
const car_scene = preload("res://scenes/props/car.tscn")
const map_texture_instancer = preload("res://map_texture_instancer.tscn")

@export var tilemap : TileMap
@export var enemy_manager : EnemyManager
@export var prop_list : EnemyList
@export var crate_list : EnemyList
@export var dust_scene : PackedScene

enum {
	ground = 0,
	ceiling = 1,
	wall = 2,
	bedrock = 3,
	shadow = 14,
	none = -1
}

var walker_spawn_chance : float = 0.05
var walker_destroy_chance : float = 0.05
@export_group("Walker Settings")
@export var walker_turn_chance : float = 0.25
@export var max_steps_until_turn : int = 4
@export var max_walkers : int = 10
var walkers : Array[Walker]
var map : Array[Vector2]

@export_group("Level Settings")
@export var max_level_size : int = 600
@export var prop_chance : float = 0.6
#@export var crate_amount : int = 4

@export_group("Room Settings")
@export var room_chance : float = 0.5
@export var max_room_size_x : int = 2
@export var max_room_size_y : int = 2
var rooms = []

@export_group("Texture Room Settings")
@export var texture_rooms : Array[Texture2D]

var used_positions = []
var texture_room_positions = []
var prop_positions = []
var crate_positions = []
var spawner_positions = []

var base_layer : Node2D
var offset = Vector2(8, 8)
var noise : FastNoiseLite


func _ready():
	base_layer = get_tree().get_first_node_in_group("base_layer")
	noise = FastNoiseLite.new()
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	
	create_floors()
	create_prefab_rooms()
	create_ceiling(ceiling, 8)
	create_ceiling(bedrock, 2)
	create_walls()
	#create_canopy()
	create_overlay()
	create_ore()
	populate_level()


func create_floors():
	var first_walker = Walker.new(Vector2.ZERO, walker_turn_chance, max_steps_until_turn)
	first_walker.changed_direction.connect(on_walker_changed_direction)
	walkers.append(first_walker)
	create_room(Vector2.ZERO)
	
	var iterations : int = 0
	while iterations < 30000:
		for walker in walkers:
			var position = walker.walk()
			var random_tile = Vector2i(randi_range(0, 2), 0)
			tilemap.set_cell(0, position, ground, random_tile)
			map.append(position)
			
			#create rooms
			if randf() < room_chance:
				create_room(position)
			
			#find potential positions for texture rooms
			get_random_tile_position(position, texture_room_positions, 16)
			
			#find potential positions for enemy spawners
			get_random_tile_position(position, spawner_positions)
			
			#find potential positions for props
			if randf() <= prop_chance:
				get_random_tile_position(position, prop_positions)
				get_ground_without_neighbors(prop_positions, 1)
			
			#check if we are going to destroy a walker
			if randf() < walker_destroy_chance and walkers.size() > 1:
				walker.queue_free()
				break
			
			#check if we should spawn a new walker
			if randf() < walker_spawn_chance and walkers.size() < max_walkers:
				var new_walker = Walker.new(walker.position, walker_turn_chance, max_steps_until_turn)
				new_walker.changed_direction.connect(on_walker_changed_direction)
				walkers.append(new_walker)
		
		var ground_tiles = tilemap.get_used_cells_by_id(0, ground)
		if ground_tiles.size() >= max_level_size:
			break
		
		iterations += 1
	
	for walker in walkers:
		walker.queue_free()
	
	walkers.clear()


func on_walker_changed_direction(position):
	get_random_tile_position(position, crate_positions)
	get_ground_without_neighbors(crate_positions, 1)


func create_room(position):
	var size_x = randi() % 2 + max_room_size_x
	var size_y = randi() % 2 + max_room_size_y
	var room_size = Vector2(size_x, size_y)
	var top_left_corner = (position - room_size / 2).floor()
	rooms.append(append_room(position, room_size))
	for y in room_size.y:
		for x in room_size.x:
			var new_step = top_left_corner + Vector2(x, y)
			var random_tile = Vector2i(randi_range(0, 2), 0)
			tilemap.set_cell(0, new_step, ground, random_tile)
			map.append(new_step)


func append_room(position, size):
	return {position = position, size = size}


func get_room_tiles(room):
	var room_tiles : Array[Vector2] = []
	var top_left_corner = (room.position - room.size / 2).floor()
	for y in room.size.y:
		for x in room.size.x:
			var new_step = top_left_corner + Vector2(x, y)
			room_tiles.append(new_step)
	
	return room_tiles


func get_end_room():
	var end_room = rooms.front()
	var starting_position = map.front()
	for room in rooms:
		if starting_position.distance_to(room.position) > starting_position.distance_to(end_room.position):
			end_room = room
	
	return end_room


func create_ceiling(tile_type, padding : int):
	var tilemap_size = tilemap.get_used_rect()
	var used_tiles = tilemap.get_used_cells(0)
	for x in range(tilemap_size.position.x - padding, tilemap_size.end.x + padding):
		for y in range(tilemap_size.position.y - padding, tilemap_size.end.y + padding):
			var tile = Vector2i(x, y)
			if used_tiles.has(tile):
				continue
			
			tilemap.set_cell(0, tile, tile_type, Vector2i.ZERO)


#func create_canopy():
	#for tile in ceiling_map:
		#var top_tile = tilemap.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_TOP_SIDE)
		#var right_tile = tilemap.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_RIGHT_SIDE)
		#var bottom_tile = tilemap.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
		#var left_tile = tilemap.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_LEFT_SIDE)
		#if tilemap.get_cell_source_id(0, top_tile) != ceiling:
			#var canopy_instance = create_instance(canopy, top_tile, offset) as Canopy
			#canopy_instance.setup(6)
		#if tilemap.get_cell_source_id(0, right_tile) != ceiling:
			#var canopy_instance = create_instance(canopy, right_tile, offset) as Canopy
			#canopy_instance.setup(1)
		#if tilemap.get_cell_source_id(0, bottom_tile) == wall:
			#var canopy_instance = create_instance(canopy, bottom_tile, offset) as Canopy
			#canopy_instance.setup(7)
		#if tilemap.get_cell_source_id(0, left_tile) != ceiling:
			#var canopy_instance = create_instance(canopy, left_tile, offset) as Canopy
			#canopy_instance.setup(0)


func create_walls():
	#create wall tiles on the top of the map
	var ceiling_tiles = tilemap.get_used_cells_by_id(0, ceiling)
	for tile in ceiling_tiles:
		var bottom_tile = tilemap.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
		if tilemap.get_cell_source_id(0, bottom_tile) == ceiling:
			continue
		
		tilemap.set_cell(0, tile, wall, Vector2i.ZERO)
		tilemap.set_cell(1, tile, ceiling, Vector2i(0, 1))
		tilemap.set_cell(1, bottom_tile, shadow, Vector2i.ZERO)


func create_prefab_rooms():
	var texture_room_instance : MapTextureInstancer
	for tile in texture_room_positions:
		var random_texture_room = texture_rooms.pick_random()
		texture_room_instance = create_instance(map_texture_instancer, tile, offset) as MapTextureInstancer
		texture_room_instance.texture = random_texture_room
		texture_room_instance.setup()


func create_overlay():
	noise.frequency = 0.2
	noise.seed = randi()
	var threshold = 0.2
	
	var ground_tiles = tilemap.get_used_cells_by_id(0, ground)
	for tile in ground_tiles:
		if noise.get_noise_2d(tile.x, tile.y) > threshold:
			tilemap.set_cell(0, tile, ground, Vector2i(0, 1))


func create_ore():
	noise.frequency = 0.24
	noise.seed = randi()
	var threshold = 0.6
	
	var ceiling_tiles = tilemap.get_used_cells_by_id(0, ceiling)
	var wall_tiles = tilemap.get_used_cells_by_id(0, wall)
	
	var ore_tiles : Array[Vector2i] = []
	var check_tiles = ceiling_tiles + wall_tiles
	for tile in check_tiles:
		var neighbors = tilemap.get_surrounding_cells(tile)
		for neighbor in neighbors:
			if tilemap.get_cell_source_id(0, neighbor) == ground:
				if noise.get_noise_2d(tile.x, tile.y) > threshold:
					ore_tiles.append(tile)
					if tilemap.get_cell_source_id(0, tile) == ceiling:
						tilemap.set_cell(0, tile, ceiling, Vector2i(1, 0))
					if tilemap.get_cell_source_id(0, tile) == wall:
						tilemap.set_cell(0, tile, wall, Vector2i(1, 0))
						tilemap.set_cell(1, tile, ceiling, Vector2i(1, 1))
	
	for tile in ore_tiles:
		var vein_size : int = 0
		while vein_size < 6:
			var ore_neighbors = tilemap.get_surrounding_cells(tile)
			var neighbor = ore_neighbors.pick_random()
			if tilemap.get_cell_source_id(0, neighbor) == ceiling:
				if noise.get_noise_2d(tile.x, tile.y) > threshold:
					tilemap.set_cell(0, neighbor, ceiling, Vector2i(1, 0))
					vein_size += 1
			
			if tilemap.get_cell_source_id(0, neighbor) == wall:
				if noise.get_noise_2d(tile.x, tile.y) > threshold:
					tilemap.set_cell(0, neighbor, wall, Vector2i(1, 0))
					tilemap.set_cell(1, neighbor, ceiling, Vector2i(1, 1))
					vein_size += 1
			
			if randf() < 0.1:
				break


func populate_level():
	#place the player
	var player = create_instance(player_scene, rooms.front().position)
	var limits = tilemap.get_used_rect()
	player.setup_camera(limits.position, limits.end)
	player.setup_inventory()
	
	#place the teleporter
	create_instance(teleporter_scene, rooms.front().position)
	for tile in get_room_tiles(rooms.front()):
		used_positions.append(tile)
	
	#place the generator
	var end_room = get_end_room()
	create_instance(generator_scene, end_room.position)
	for tile in get_room_tiles(end_room):
		used_positions.append(tile)
	
	#place crates
	#crate_list.setup()
	for crate_position in crate_positions:
		#var crate_position = crate_positions.pick_random()
		var crate_scene = crate_list.spawn_table.pick_item()
		create_instance(crate_scene, crate_position, offset)
	
	#place enemy spawners
	for spawner_position in spawner_positions:
		var spawner_instance = create_instance(spawner_scene, spawner_position, offset)
		enemy_manager.add_spawner(spawner_instance)
		
		#place dust particles
		create_instance(dust_scene, spawner_position, offset)
	
	#place props
	#prop_list.setup()
	for prop_position in prop_positions:
		var prop_scene = prop_list.spawn_table.pick_item()
		create_instance(prop_scene, prop_position, offset)
	
	var random_room = rooms.pick_random()
	for tile in get_room_tiles(random_room):
		if used_positions.has(tile):
			return
	
	create_instance(car_scene, random_room.position)


func create_instance(scene : PackedScene, position : Vector2, offset : Vector2 = Vector2.ZERO) -> Node2D:
	var instance = scene.instantiate()
	base_layer.add_child(instance)
	instance.global_position = position * 16 + offset
	return instance


func get_random_tile_position(position, tile_locations, max_distance = 4):
	#check if position already has been used for something else
	if used_positions.has(position):
		return
	
	#check how close the position is to the start and end of the map
	if position.distance_to(rooms.front().position) < max_distance:
		return
	
	if position.distance_to(get_end_room().position) < max_distance:
		return
	
	#check previous tile positions, if they are too close chose another
	for tile in tile_locations:
		if tile.distance_to(position) < max_distance:
			return
	
	tile_locations.append(position)
	used_positions.append(position)


func get_ground_without_neighbors(tile_locations, allowed_neighbors : int = 0):
	for tile in tile_locations:
		var neighbors = check_neighbors(tile.x, tile.y)
		if neighbors > allowed_neighbors:
			tile_locations.erase(tile)


func check_neighbors(x, y):
	var count = 0
	if tilemap.get_cell_source_id(0, Vector2i(x, y - 1)) != ground: count += 1
	if tilemap.get_cell_source_id(0, Vector2i(x, y + 1)) != ground: count += 1
	if tilemap.get_cell_source_id(0, Vector2i(x - 1, y)) != ground: count += 1
	if tilemap.get_cell_source_id(0, Vector2i(x + 1, y)) != ground: count += 1
	if tilemap.get_cell_source_id(0, Vector2i(x + 1, y + 1)) != ground: count += 1
	if tilemap.get_cell_source_id(0, Vector2i(x + 1, y - 1)) != ground: count += 1
	if tilemap.get_cell_source_id(0, Vector2i(x - 1, y + 1)) != ground: count += 1
	if tilemap.get_cell_source_id(0, Vector2i(x - 1, y - 1)) != ground: count += 1
	return count

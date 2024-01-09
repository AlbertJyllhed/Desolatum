extends Node
class_name LevelGenerator

const player_scene = preload("res://characters/player.tscn")
const teleporter_scene = preload("res://scenes/props/teleport_platform.tscn")
const generator_scene = preload("res://scenes/props/generator.tscn")
#const crate_scene = preload("res://scenes/props/shop.tscn")
const spawner_scene = preload("res://enemy_spawner.tscn")
const car_scene = preload("res://scenes/props/car.tscn")
const dust_scene = preload("res://particles/dust.tscn")

@export var tilemap : TileMap
@export var enemy_manager : EnemyManager
@export var prop_list : EnemyList
@export var crate_list : EnemyList

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
@export var walker_turn_chance : float = 0.25
@export var max_steps_until_turn : int = 4
@export var max_walkers : int = 10
var walkers : Array[Walker]

var map : Array[Vector2]
@export var max_level_size : int = 600

@export var room_chance : float = 0.5
@export var max_room_size_x : int = 2
@export var max_room_size_y : int = 2
var rooms = []

@export var prop_chance : float = 0.1
@export var crate_amount : int = 4
var used_positions = []
var crate_positions = []
var prop_positions = []
var spawner_positions = []

var noise : FastNoiseLite


func _ready():
	noise = FastNoiseLite.new()
	#noise.TYPE_SIMPLEX
	noise.frequency = 0.2
	
	create_floors()
	create_walls()
	create_shadows()
	create_ceiling(ceiling, 10)
	create_ceiling(bedrock, 2)
	create_overlay()
	create_ore()
	populate_level()


func create_floors():
	var first_walker = Walker.new(Vector2.ZERO, walker_turn_chance, max_steps_until_turn)
	walkers.append(first_walker)
	create_room(Vector2.ZERO)
	
	var iterations : int = 0
	while iterations < 100000:
		for walker in walkers:
			var position = walker.walk()
			var random_tile = Vector2i(randi_range(0, 2), 0)
			tilemap.set_cell(0, position, ground, random_tile)
			map.append(position)
			
			#create rooms
			if randf() < room_chance:
				create_room(position)
			
			#find potential positions for enemy spawners
			get_random_tile_position(position, spawner_positions)
			
			#find potential positions for props
			if randf() <= prop_chance:
				get_random_tile_position(position, prop_positions)
			
			#check if we are going to destroy a walker
			if randf() < walker_destroy_chance and walkers.size() > 1:
				walker.queue_free()
				get_random_tile_position(position, crate_positions)
				break
			
			#check if we should spawn a new walker
			if randf() < walker_spawn_chance and walkers.size() < max_walkers:
				var new_walker = Walker.new(walker.position, walker_turn_chance, max_steps_until_turn)
				walkers.append(new_walker)
		
		var ground_tiles = tilemap.get_used_cells_by_id(0, ground)
		if ground_tiles.size() >= max_level_size:
			break
		
		iterations += 1
	
	for walker in walkers:
		walker.queue_free()
	
	walkers.clear()


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
	var room_tiles : Array[Vector2]
	var top_left_corner = (room.position - room.size / 2).floor()
	for y in room.size.y:
		for x in room.size.x:
			var new_step = top_left_corner + Vector2(x, y)
			room_tiles.append(new_step)
	
	return room_tiles


func create_walls():
	#create wall tiles on the top of the map
	var ground_tiles = tilemap.get_used_cells_by_id(0, ground)
	for tile in ground_tiles:
		var top_tile = tilemap.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_TOP_SIDE)
		if tilemap.get_cell_source_id(0, top_tile) == none:
			tilemap.set_cell(0, top_tile, wall, Vector2i.ZERO)
			tilemap.set_cell(1, top_tile, ceiling, Vector2i(0, 1))


func create_shadows():
	var wall_tiles = tilemap.get_used_cells_by_id(0, wall)
	for tile in wall_tiles:
		var bottom_tile = tilemap.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
		tilemap.set_cell(1, bottom_tile, shadow, Vector2i.ZERO)


func create_ceiling(tile_type, padding : int):
	var tilemap_size = tilemap.get_used_rect()
	for x in range(tilemap_size.position.x - padding, tilemap_size.end.x + padding):
		for y in range(tilemap_size.position.y - padding, tilemap_size.end.y + padding):
			var tile = Vector2i(x, y)
			var used_tiles = tilemap.get_used_cells(0)
			if used_tiles.has(tile):
				continue
			
			tilemap.set_cell(0, tile, tile_type, Vector2i.ZERO)


func create_overlay():
	var threshold = 0.2
	noise.seed = randi()
	
	var ground_tiles = tilemap.get_used_cells_by_id(0, ground)
	for tile in ground_tiles:
		if noise.get_noise_2d(tile.x, tile.y) > threshold:
			tilemap.set_cell(0, tile, ground, Vector2i(0, 1))


func create_ore():
	var threshold = 0.3
	noise.seed = randi()
	
	#process ceiling tiles
	var ceiling_tiles = tilemap.get_used_cells_by_id(0, ceiling)
	for tile in ceiling_tiles:
		if noise.get_noise_2d(tile.x, tile.y) > threshold:
			tilemap.set_cell(0, tile, ceiling, Vector2i(1, 0))
	
	#process wall tiles
	var wall_tiles = tilemap.get_used_cells_by_id(0, wall)
	for tile in wall_tiles:
		if randf() > 0.1:
			continue
		
		#create ore walls and top them off
		tilemap.set_cell(0, tile, wall, Vector2i(2, 0))
		tilemap.set_cell(1, tile, ceiling, Vector2i(2, 1))
		
		if noise.get_noise_2d(tile.x, tile.y) > threshold:
			#create crystal walls and top them off
			tilemap.set_cell(0, tile, wall, Vector2i(1, 0))
			tilemap.set_cell(1, tile, ceiling, Vector2i(1, 1))


func populate_level():
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	var offset = Vector2(8, 8)
	
	#place the player
	var player = player_scene.instantiate()
	base_layer.add_child(player)
	player.global_position = rooms.front().position * 16
	var limits = tilemap.get_used_rect()
	player.setup_camera(limits.position, limits.end)
	player.setup_inventory()
	
	#place the teleporter
	var teleporter = teleporter_scene.instantiate()
	base_layer.add_child(teleporter)
	teleporter.global_position = rooms.front().position * 16
	for tile in get_room_tiles(rooms.front()):
		used_positions.append(tile)
	
	#place the generator
	var generator = generator_scene.instantiate()
	base_layer.add_child(generator)
	generator.global_position = get_end_room().position * 16
	for tile in get_room_tiles(get_end_room()):
		used_positions.append(tile)
	
	#place crates
	for i in crate_amount:
		var crate_position = crate_positions.pick_random()
		crate_list.setup()
		var crate_scene = crate_list.spawn_table.pick_item()
		var crate_instance = crate_scene.instantiate()
		base_layer.add_child(crate_instance)
		crate_instance.global_position = crate_position * 16 + offset
		crate_positions.erase(crate_position)
	
	#var handled_tiles = get_ground_without_neighbors()
	#for i in crate_amount:
		#var crate_position = handled_tiles.pick_random()
		#var crate_instance = crate_scene.instantiate()
		#base_layer.add_child(crate_instance)
		#crate_instance.global_position = tilemap.to_global(crate_position) * 16 + offset
		#handled_tiles.erase(crate_position)
	
	#place enemy spawners
	for spawner_position in spawner_positions:
		#var spawner_instance = spawner_scene.instantiate() as EnemySpawner
		#base_layer.add_child(spawner_instance)
		#spawner_instance.global_position = spawner_position * 16 + offset
		#enemy_manager.add_spawner(spawner_instance)
		
		#place dust particles
		var dust_instance = dust_scene.instantiate() as Node2D
		base_layer.add_child(dust_instance)
		dust_instance.global_position = spawner_position * 16 + offset
	
	#place props
	for prop_position in prop_positions:
		prop_list.setup()
		var prop_scene = prop_list.spawn_table.pick_item()
		var prop_instance = prop_scene.instantiate() as Node2D
		base_layer.add_child(prop_instance)
		prop_instance.global_position = prop_position * 16 + offset
	
	var random_room = rooms.pick_random()
	for tile in get_room_tiles(random_room):
		if used_positions.has(tile):
			return
	
	var car_instance = car_scene.instantiate() as Node2D
	base_layer.add_child(car_instance)
	car_instance.global_position = random_room.position * 16


func get_end_room():
	var end_room = rooms.front()
	var starting_position = map.front()
	for room in rooms:
		if starting_position.distance_to(room.position) > starting_position.distance_to(end_room.position):
			end_room = room
	
	return end_room


func get_random_tile_position(position, tile_locations):
	#check if position already has been used for something else
	if used_positions.has(position):
		return
	
	#check how close the position is to the start and end of the map
	var start_room_position = rooms.front().position
	if position.distance_to(start_room_position) < 4:
		return
	
	var end_room_position = get_end_room().position
	if position.distance_to(end_room_position) < 4:
		return
	
	#check previous tile positions, if they are too close chose another
	for tile in tile_locations:
		if tile.distance_to(position) < 4:
			return
	
	tile_locations.append(position)
	used_positions.append(position)


func get_ground_without_neighbors():
	var ground_tiles = tilemap.get_used_cells_by_id(0, ground)
	for tile in ground_tiles:
		var neighbors = tilemap.get_surrounding_cells(tile)
		var neighbor_count = 0
		for neighbor in neighbors:
			if tilemap.get_cell_source_id(0, neighbor) != ground:
				neighbor_count += 1
			
			if neighbor_count > 1:
				ground_tiles.erase(tile)
	
	return ground_tiles

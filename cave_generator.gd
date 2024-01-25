extends TileMap

const player_scene = preload("res://characters/player.tscn")
const teleporter_scene = preload("res://scenes/props/teleport_platform.tscn")
const generator_scene = preload("res://scenes/props/generator.tscn")
const spawner_scene = preload("res://enemy_spawner.tscn")
const car_scene = preload("res://scenes/props/car.tscn")
const dust_scene = preload("res://particles/dust.tscn")

@export var map_w : int = 60
@export var map_h : int = 60
@export var iterations : int = 20000
@export var neighbors : int = 4
@export var ground_chance : float = 0.48
@export var min_cave_size : int = 80

@export var prop_list : EnemyList
@export var min_props_per_room : int = 1
@export var max_props_per_room : int = 4

@export var enemy_manager : EnemyManager

enum {
	ground = 0,
	ceiling = 1,
	wall = 2,
	bedrock = 3,
	shadow = 14,
	none = -1
}

var noise : FastNoiseLite
var caves = []
var used_positions : Array[Vector2i]
var base_layer : Node2D


func _ready():
	create_ceiling()
	create_ground()
	dig_caves()
	get_caves()
	connect_caves()
	smooth_cave()
	populate_level()
	create_walls()
	
	noise = FastNoiseLite.new()
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	create_overlay()
	create_ore()


func create_ceiling():
	for x in range(0, map_w):
		for y in range(0, map_h):
			set_cell(0, Vector2i(x, y), ceiling, Vector2i.ZERO)


func create_ground():
	for x in range(8, map_w - 8):
		for y in range(8, map_h - 8):
			if randf() < ground_chance:
				var random_tile = Vector2i(randi_range(0, 2), 0)
				set_cell(0, Vector2i(x, y), ground, random_tile)


func dig_caves():
	for i in range(iterations):
		# Pick a random point with a 8-tile buffer within the map
		var x = floor(randi_range(8, map_w - 8))
		var y = floor(randi_range(8, map_h - 8))
		var tile = Vector2i(x, y)
		
		# if nearby cells > neighbors, make it a ceiling tile
		if check_neighbors(x, y) > neighbors:
			set_cell(0, tile, ceiling, Vector2i.ZERO)
		
		# or make it the ground tile
		elif check_neighbors(x, y) < neighbors:
			var random_tile = Vector2i(randi_range(0, 2), 0)
			set_cell(0, tile, ground, random_tile)


func check_neighbors(x, y):
	var count = 0
	if get_cell_source_id(0, Vector2i(x, y - 1)) == ceiling: count += 1
	if get_cell_source_id(0, Vector2i(x, y + 1)) == ceiling: count += 1
	if get_cell_source_id(0, Vector2i(x - 1, y)) == ceiling: count += 1
	if get_cell_source_id(0, Vector2i(x + 1, y)) == ceiling: count += 1
	if get_cell_source_id(0, Vector2i(x + 1, y + 1)) == ceiling: count += 1
	if get_cell_source_id(0, Vector2i(x + 1, y - 1)) == ceiling: count += 1
	if get_cell_source_id(0, Vector2i(x - 1, y + 1)) == ceiling: count += 1
	if get_cell_source_id(0, Vector2i(x - 1, y - 1)) == ceiling: count += 1
	return count


func get_caves():
	caves = []
	
	for x in range (0, map_w):
		for y in range (0, map_h):
			if get_cell_source_id(0, Vector2i(x, y)) == ground:
				flood_fill(x, y)
	
	for cave in caves:
		for tile in cave:
			var random_tile = Vector2i(randi_range(0, 2), 0)
			set_cell(0, tile, ground, random_tile)


func flood_fill(tilex, tiley):
	var cave = []
	var to_fill = [Vector2i(tilex, tiley)]
	while to_fill:
		var tile = to_fill.pop_back()
		
		if !cave.has(tile):
			cave.append(tile)
			set_cell(0, tile, ceiling, Vector2i.ZERO)
			
			#check adjacent cells
			var north = Vector2i(tile.x, tile.y-1)
			var south = Vector2i(tile.x, tile.y+1)
			var east  = Vector2i(tile.x+1, tile.y)
			var west  = Vector2i(tile.x-1, tile.y)
			
			for dir in [north,south,east,west]:
				if get_cell_source_id(0, dir) == ground:
					if !to_fill.has(dir) and !cave.has(dir):
						to_fill.append(dir)

	if cave.size() >= min_cave_size:
		caves.append(cave)


func connect_caves():
	var prev_cave = null
	var tunnel_caves = caves.duplicate()
	
	for cave in tunnel_caves:
		if prev_cave:
			var new_point = cave.pick_random()
			var prev_point = prev_cave.pick_random()
			
			# ensure not the same point
			if new_point != prev_point:
				create_tunnel(new_point, prev_point, cave)
		
		prev_cave = cave


func create_tunnel(point1, point2, cave):
	var max_steps = 500
	var steps = 0
	var drunk_x = point2[0]
	var drunk_y = point2[1]
	
	while steps < max_steps and !cave.has(Vector2(drunk_x, drunk_y)):
		steps += 1
		
		# set initial dir weights
		var n       = 1.0
		var s       = 1.0
		var e       = 1.0
		var w       = 1.0
		var weight  = 1
		
		# weight the random walk against edges
		if drunk_x < point1.x: # drunkard is left of point1
			e += weight
		elif drunk_x > point1.x: # drunkard is right of point1
			w += weight
		if drunk_y < point1.y: # drunkard is above point1
			s += weight
		elif drunk_y > point1.y: # drunkard is below point1
			n += weight
		
		# normalize probabilities so they form a range from 0 to 1
		var total = n + s + e + w
		n /= total
		s /= total
		e /= total
		w /= total
		
		var dx
		var dy
		
		# choose the direction
		var choice = randf()
		
		if 0 <= choice and choice < n:
			dx = 0
			dy = -1
		elif n <= choice and choice < (n+s):
			dx = 0
			dy = 1
		elif (n+s) <= choice and choice < (n+s+e):
			dx = 1
			dy = 0
		else:
			dx = -1
			dy = 0
		
		# ensure not to walk past edge of map
		if (2 < drunk_x + dx and drunk_x + dx < map_w-2) and \
			(2 < drunk_y + dy and drunk_y + dy < map_h-2):
			drunk_x += dx
			drunk_y += dy
			if get_cell_source_id(0, Vector2i(drunk_x, drunk_y)) == ceiling:
				set_cell(0, Vector2i(drunk_x, drunk_y), ground, Vector2i.ZERO)
				#set_cell(0, Vector2i(drunk_x + 1, drunk_y), ground, Vector2i.ZERO)
				#set_cell(0, Vector2i(drunk_x + 1, drunk_y + 1), ground, Vector2i.ZERO)


func smooth_cave():
	var ceiling_tiles = get_used_cells_by_id(0, ceiling)
	var wall_tiles = get_used_cells_by_id(0, wall)
	var check_tiles = ceiling_tiles + wall_tiles
	
	for tile in check_tiles:
		if check_neighbors(tile.x, tile.y) < 2:
			set_cell(0, tile, ground, Vector2i.ZERO)


func create_walls():
	var ceiling_tiles = get_used_cells_by_id(0, ceiling)
	for tile in ceiling_tiles:
		var bottom_tile = get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
		if get_cell_source_id(0, bottom_tile) == ground:
			set_cell(0, tile, wall, Vector2i.ZERO)
			set_cell(1, tile, ceiling, Vector2i(0, 1))
			set_cell(1, bottom_tile, shadow, Vector2i.ZERO)


func create_overlay():
	var threshold = 0.3
	
	for cave in caves:
		noise.frequency = randf_range(0.05, 0.08)
		noise.seed = randi()
		for tile in cave:
			if get_cell_source_id(0, tile) == ground:
				if noise.get_noise_2d(tile.x, tile.y) > threshold:
					set_cell(0, tile, ground, Vector2i(0, 1))


func create_ore():
	noise.frequency = 0.24
	var threshold = 0.6
	noise.seed = randi()
	
	var ore_tiles : Array[Vector2i]
	
	var ceiling_tiles = get_used_cells_by_id(0, ceiling)
	var wall_tiles = get_used_cells_by_id(0, wall)
	var check_tiles = ceiling_tiles + wall_tiles
	
	for tile in check_tiles:
		var neighbors = get_surrounding_cells(tile)
		for neighbor in neighbors:
			if get_cell_source_id(0, neighbor) == ground:
				if noise.get_noise_2d(tile.x, tile.y) > threshold:
					ore_tiles.append(tile)
					if get_cell_source_id(0, tile) == ceiling:
						set_cell(0, tile, ceiling, Vector2i(1, 0))
					if get_cell_source_id(0, tile) == wall:
						set_cell(0, tile, wall, Vector2i(1, 0))
						set_cell(1, tile, ceiling, Vector2i(1, 1))
	
	for tile in ore_tiles:
		var vein_size : int = 0
		while vein_size < 6:
			var ore_neighbors = get_surrounding_cells(tile)
			var neighbor = ore_neighbors.pick_random()
			if get_cell_source_id(0, neighbor) == ceiling:
				if noise.get_noise_2d(tile.x, tile.y) > threshold:
					set_cell(0, neighbor, ceiling, Vector2i(1, 0))
					vein_size += 1
			
			if get_cell_source_id(0, neighbor) == wall:
				if noise.get_noise_2d(tile.x, tile.y) > threshold:
					set_cell(0, neighbor, wall, Vector2i(1, 0))
					set_cell(1, neighbor, ceiling, Vector2i(1, 1))
					vein_size += 1
			
			if randf() < 0.1:
				break


func populate_level():
	base_layer = get_tree().get_first_node_in_group("base_layer")
	
	var starting_position = get_starting_cave().pick_random()
	#var player = create_instance(player_scene, starting_position)
	#var limits = get_used_rect()
	#player.setup_camera(limits.position, limits.end)
	#player.setup_inventory()
	
	create_instance(teleporter_scene, starting_position)
	carve_room(starting_position)
	
	var end_position = get_end_cave(starting_position)
	create_instance(generator_scene, end_position)
	carve_room(end_position)
	
	var offset = Vector2(8, 8)
	
	#place large props
	for i in randi_range(0, 2):
		var random_tile = get_random_tile(caves.pick_random(), 0)
		create_instance(car_scene, random_tile)
		carve_room(random_tile)
	
	#place enemy spawners
	for cave in caves:
		var cave_percentage = float(cave.size()) / 100.0
		var spawner_amount = 16 * int(cave_percentage)
		for i in spawner_amount:
			var spawner_instance = create_instance(spawner_scene, get_random_tile(cave, 6), offset)
		#enemy_manager.add_spawner(spawner_instance)
	
	#place props
	prop_list.setup()
	for cave in caves:
		var cave_percentage = float(cave.size()) / 100.0
		var prop_amount = (randi_range(min_props_per_room, max_props_per_room) + int(cave_percentage))
		for i in prop_amount:
			var prop_scene = prop_list.spawn_table.pick_item()
			create_instance(prop_scene, get_random_tile(cave, 1), offset)


func create_instance(scene : PackedScene, position : Vector2, offset : Vector2 = Vector2.ZERO) -> Node2D:
	var instance = scene.instantiate()
	base_layer.add_child(instance)
	instance.global_position = position * 16 + offset
	return instance


func get_starting_cave():
	var starting_cave = caves.front()
	for cave in caves:
		if cave.size() < starting_cave.size():
			starting_cave = cave
	
	return starting_cave


func get_end_cave(start_cave_tile : Vector2):
	var end_cave_tile = caves.front().pick_random()
	for cave in caves:
		var tile = cave.pick_random()
		if start_cave_tile.distance_to(tile) > start_cave_tile.distance_to(end_cave_tile):
			end_cave_tile = tile
	
	return end_cave_tile


func carve_room(position : Vector2):
	var room_size = Vector2(4, 4)
	var top_left_corner = (position - room_size / 2).floor()
	for y in room_size.y:
		for x in room_size.x:
			var new_step = top_left_corner + Vector2(x, y)
			var random_tile = Vector2i(randi_range(0, 2), 0)
			set_cell(0, new_step, ground, random_tile)
			used_positions.append(Vector2i(new_step))


func get_random_tile(cave, allowed_neighbors : int) -> Vector2i:
	var random_tile : Vector2i
	var potential_tiles : Array[Vector2i]
	for tile in cave:
		if used_positions.has(tile):
			continue
		
		random_tile = tile
		
		var neighbors = check_neighbors(tile.x, tile.y)
		if neighbors <= allowed_neighbors:
			potential_tiles.append(tile)
	
	if potential_tiles.size() > 0:
		random_tile = potential_tiles.pick_random()
	
	used_positions.append(random_tile)
	return random_tile

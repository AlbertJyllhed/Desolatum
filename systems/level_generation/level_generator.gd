extends Node
class_name LevelGenerator
## Random-walker cave generator.
##
## generate() runs these steps:
##   1. Walkers carve the floor; rooms are stamped where walkers turn.
##   2. Noise adds the alternate "overlay" ground tile.
##   3. Prefab texture rooms are stamped, then the layout is validated with a
##      flood fill. If the level got cut apart, steps 1-3 are retried.
##   4. The end room is the room farthest from the start by walking distance.
##   5. Crates, props and enemy spawners are placed.
##   6. Ceiling, bedrock and walls are built, then energy and ore are scattered
##      in the rock. Energy is budgeted from the cost of the shops (see below).
##   7. Scenes are instantiated.
##
## Everything random goes through Godot's global RNG, which generate() seeds,
## so the same seed always produces the same level.

const PLAYER_SCENE = preload("uid://oigv3iu1oim1")
const TELEPORTER_SCENE = preload("uid://bq3lkkalp320y")
const GENERATOR_SCENE = preload("uid://cp2pu6pn5wy7b")
const SPAWNER_SCENE = preload("uid://bsu0qwh6vyytv")
const CAR_SCENE = preload("uid://bnrmggvnbauyb")
const MAP_TEXTURE_INSTANCER_SCENE = preload("uid://cwva45143mwml")

const Tile = Tiles.Id

const CARDINALS: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## The 8 tiles around a tile, in circular order starting at the top. Neighbours
## next to each other in this list share an edge, and even indices are the four
## edge neighbours (up, right, down, left).
const RING: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const SMOOTH_FILL_MIN_NEIGHBORS := 5   # rock with at least this many floor neighbours becomes floor
const SMOOTH_ERODE_MAX_NEIGHBORS := 3  # floor with at most this many floor neighbours may be removed

const OVERLAY_NOISE_FREQUENCY := 0.2
const OVERLAY_NOISE_THRESHOLD := 0.2
## Column in the ceiling/wall atlases that holds each mineral (tile custom data
## ore_type 1 = energy, 2 = ore).
const ENERGY_ATLAS_X := 1
const ORE_ATLAS_X := 2
const MIN_RELAXED_SPACING := 2  # placement spacing is never relaxed below this
const CAR_SPACING := 5          # keep the car this far from the start and end rooms

const CEILING_PADDING := 8
const BEDROCK_PADDING := 2

@export var tilemap: TileMapLayer
@export var overlay_layer: TileMapLayer
@export var enemy_manager: EnemyManager
@export var prop_list: EnemyList
@export var crate_list: PropList
@export var dust_scene: PackedScene
## Parent for everything that gets spawned. If empty, the first node in the
## "base_layer" group is used.
@export var base_layer: Node2D

@export_group("Seed")
@export var randomize_seed: bool = true
## Only used when randomize_seed is off. Handy for reproducing a bad level.
@export var level_seed: int = 0

@export_group("Walker Settings")
@export_range(0.0, 1.0, 0.01) var walker_spawn_chance: float = 0.05
@export_range(0.0, 1.0, 0.01) var walker_destroy_chance: float = 0.05
@export_range(0.0, 1.0, 0.01) var walker_turn_chance: float = 0.25
@export var max_steps_until_turn: int = 4
@export var max_walkers: int = 10
## Turn off for longer, less blobby paths.
@export var walkers_can_u_turn: bool = true
## Safety cap on the carving loop.
@export var max_walker_iterations: int = 30000
## How many tiles wide the paths are. Every walker step carves a square this big.
@export_range(1, 3, 1, "or_greater") var path_width: int = 2
## Wide paths look blobby if walkers turn as often as they do for 1-tile paths.
## When on, the turn chance is divided by path_width and the longest straight
## run is multiplied by it.
@export var scale_turns_with_path_width: bool = true

@export_group("Smoothing")
## Makes caves look less boxy. Each pass fills in rock tiles that are mostly
## surrounded by floor, then removes floor tiles that stick out, without ever
## disconnecting the level. 0 turns it off. Corners get rounded and small gaps
## close, so the level ends up slightly more open, and dead ends can get a tile
## or so shorter per pass.
@export_range(0, 3) var smoothing_passes: int = 1

@export_group("Level Settings")
## Floor tiles to carve before stopping. Wider paths use up tiles faster, so
## raise this along with path_width (roughly x path_width keeps the level about
## as long).
@export var max_level_size: int = 1200
@export var texture_room_amount: int = 3
@export var crate_amount: int = 6
@export var prop_amount: int = 14
@export var spawner_amount: int = 20
## How many tiles each object covers, as width x height. A 32x32 sprite on a 16x16
## grid is 2x2. Objects are centered on their footprint, so their scenes should
## have the sprite centered on the node's origin. Crates, props, the car and the
## generator are treated as solid: they are only placed where they don't cut the
## level apart.
@export var car_size: Vector2i = Vector2i(2, 2)
@export var teleporter_size: Vector2i = Vector2i(2, 2)
@export var generator_size: Vector2i = Vector2i(2, 2)
@export var crate_size: Vector2i = Vector2i.ONE
@export var prop_size: Vector2i = Vector2i.ONE
## The player spawns on the teleporter, so it is not solid by default. Turn this
## on if it has collision that should be kept from blocking a passage.
@export var teleporter_is_solid: bool = false

@export_group("Energy")
## Energy tiles placed = the combined energy cost of the crate shops * this. Crystal
## clusters and enemy drops come on top, so 1.0 already leaves some slack.
@export var energy_surplus: float = 1.25
## Floor for levels with few or no shops.
@export var min_energy_tiles: int = 0
## Every vein starts on a tile that touches the floor, then grows into the rock.
## This is how deep (in tiles from the floor) it may grow. 1 = along the wall face only.
@export var energy_max_depth: int = 3
## Tiles per vein, including the starting tile.
@export var energy_vein_size := Vector2i(2, 4)
## Minimum distance (tiles) between vein starting points. Relaxed if there is no room.
@export var energy_min_spacing: int = 6
## Lower = smoother, more sweeping veins. Higher = more ragged.
@export var energy_noise_frequency: float = 0.2

@export_group("Ore")
## Ore tiles hidden in the walls. Ore pays for buildings, so this is much more
## common than energy. Each tile gives 1 ore.
@export var ore_amount: int = 80
## How many tiles deep into the rock ore may hide. 1 = only tiles touching the floor.
@export var ore_max_depth: int = 3
## Tiles per cluster. Clusters grow along the noise, so they come out irregular.
@export var ore_vein_size := Vector2i(8, 16)
## Minimum distance (tiles) between cluster centres. Relaxed if there is no room.
@export var ore_min_spacing: int = 8
## Lower = bigger, smoother blobs. Higher = more, smaller patches.
@export var ore_noise_frequency: float = 0.12
## Ore never spawns closer than this (tiles) to an energy tile.
@export var ore_energy_clearance: int = 3

@export_group("Room Settings")
## Chance that a walker leaves a room behind when it turns.
@export_range(0.0, 1.0, 0.01) var room_chance: float = 0.5
@export var min_room_size_x: int = 2
@export var min_room_size_y: int = 2
@export var max_room_size_x: int = 3
@export var max_room_size_y: int = 3
## Rooms are never created closer together than this (in tiles).
@export var min_room_spacing: int = 4
## The start room is carved at this size, and the end room is enlarged to it.
## The teleporter and generator sit in the middle, so a room two tiles bigger
## than the object leaves a walkable ring around it.
@export var start_room_size: Vector2i = Vector2i(4, 4)
@export var end_room_size: Vector2i = Vector2i(4, 4)

@export_group("Secret Rooms")
@export var secret_room_amount: int = 2
## Area reserved per room. The walker never leaves it.
@export var secret_room_size: Vector2i = Vector2i(10, 8)
## Floor tiles carved per room (including the 3x3 vault)
@export var secret_room_tiles: int = 30
## Minimum rock (tiles) between the main level and a secret room
@export var secret_rock_thickness: int = 3
## Spawned in the middle of each room, e.g. a crate.
@export var secret_reward_scene: PackedScene

@export_group("Texture Room Settings")
@export var room_textures: Array[Texture2D]
## Empty tiles kept between a prefab and the start room / other prefabs.
@export var texture_room_margin: int = 2

@export_group("Validation")
## How many times to re-roll the layout if prefabs cut the level apart.
@export var max_generation_attempts: int = 5
## If less than this fraction of the floor is reachable from the start room, the
## layout is re-rolled. Smaller cut-off pockets are just filled in with rock.
@export_range(0.5, 1.0, 0.01) var min_reachable_fraction: float = 0.95
## TileSet source ids the player can walk on. Add the ids your prefab rooms use
## for floor if they differ from the normal ground.
@export var walkable_tile_ids: Array[int] = [Tile.GROUND]

@export_group("Debug")
@export var debug_log: bool = false

var current_seed: int = 0

var start_room: Room
var end_room: Room
var teleporter_rect: Rect2i  # the tiles the teleporter covers (in the start room)
var generator_rect: Rect2i   # the tiles the generator covers (in the end room)
var rooms: Array[Room] = []

var secret_cells := {}
var secret_reward_cells: Array[Vector2i] = []

var overlay_noise: FastNoiseLite
var floor_cells := {}     # Vector2i -> true. Every cell the walkers and rooms carved.
var reach_distance := {}  # Vector2i -> walking steps from the start room.

var prefab_footprints: Array[Rect2i] = []
var prefab_instancers: Array[MapTextureInstancer] = []

var used_positions: Array[Vector2i] = []  # points that new placements keep their distance from
var reserved_cells := {}                  # Vector2i -> true. Cells that must stay free.
var solid_cells := {}                     # Vector2i -> true. Cells covered by solid objects.
var car_positions: Array[Vector2i] = []   # top-left cell of each footprint
var crate_positions: Array[Vector2i] = []
var crate_items: Array[PropItem] = []     # what stands on each crate position
var prop_positions: Array[Vector2i] = []
var spawner_positions: Array[Vector2i] = []


## A rectangular room. [member center] is the cell the walker was on.
class Room extends RefCounted:
	var center: Vector2i
	var rect: Rect2i

	func _init(room_center: Vector2i, room_size: Vector2i) -> void:
		center = room_center
		rect = Rect2i(room_center - room_size / 2, room_size)


func _ready() -> void:
	assert(tilemap and overlay_layer, "Assign both tile layers on the LevelGenerator")
	overlay_layer.tile_set = tilemap.tile_set
	generate(randi() if randomize_seed else level_seed)
	TileBreaker.register(tilemap, overlay_layer)


func generate(new_seed: int) -> void:
	current_seed = new_seed
	seed(current_seed)
	print("LevelGenerator seed: %d" % current_seed)

	if base_layer == null:
		base_layer = get_tree().get_first_node_in_group("base_layer") as Node2D
	if base_layer == null or tilemap == null:
		push_error("LevelGenerator needs a tilemap and a base_layer (or a node in the 'base_layer' group).")
		return

	# Steps 1-3, retried until the layout is connected.
	var is_valid := false
	for attempt in maxi(max_generation_attempts, 1):
		_reset_state(attempt > 0)
		_create_floors()
		_smooth_floors()
		_create_overlay()
		_place_prefab_rooms()
		is_valid = _validate_layout()
		_log("attempt %d: %s" % [attempt + 1, "ok" if is_valid else "rejected"])
		if is_valid:
			break
	if not is_valid:
		push_warning("LevelGenerator: no fully connected layout after %d attempt(s) (seed %d); using the last one." % [
			maxi(max_generation_attempts, 1), current_seed
		])

	# Steps 4-7.
	_fill_unreachable_floor()
	_choose_end_room()
	_find_tile_positions()
	_spawn_prefab_objects()
	_carve_secret_rooms()
	_create_ceiling(Tile.CEILING, CEILING_PADDING)
	_create_ceiling(Tile.BEDROCK, BEDROCK_PADDING)
	_create_walls(Tile.CEILING, Tile.WALL)
	_create_walls(Tile.SHIP_CEILING, Tile.SHIP_WALL)
	_scatter_minerals()
	_populate_level()
	GameEvents.level_generated.emit()

	# The level is done; don't leave gameplay randomness tied to the level seed.
	randomize()


func _reset_state(clear_tiles: bool) -> void:
	for instancer in prefab_instancers:
		instancer.queue_free()
	prefab_instancers.clear()
	prefab_footprints.clear()

	floor_cells.clear()
	reach_distance.clear()
	rooms.clear()
	start_room = null
	end_room = null

	used_positions.clear()
	reserved_cells.clear()
	solid_cells.clear()
	car_positions.clear()
	crate_positions.clear()
	crate_items.clear()
	prop_positions.clear()
	spawner_positions.clear()

	if clear_tiles:
		tilemap.clear()
		overlay_layer.clear()


# ---------------------------------------------------------------------------
# Step 1: floors and rooms
# ---------------------------------------------------------------------------

func _create_floors() -> void:
	var walkers: Array[Walker] = []
	start_room = _create_room(Vector2i.ZERO, start_room_size)
	_spawn_walker(walkers, Vector2i.ZERO)

	var iterations := 0
	while iterations < max_walker_iterations and floor_cells.size() < max_level_size:
		# Iterate a copy: walkers are added and removed while we loop.
		for walker in walkers.duplicate():
			_carve_path(walker.walk())

			if walkers.size() > 1 and randf() < walker_destroy_chance:
				walkers.erase(walker)
				continue

			if walkers.size() < max_walkers and randf() < walker_spawn_chance:
				_spawn_walker(walkers, walker.position)

		iterations += 1


func _spawn_walker(walkers: Array[Walker], cell: Vector2i) -> void:
	var turn_scale := float(path_width) if scale_turns_with_path_width else 1.0
	var walker := Walker.new(
		cell,
		walker_turn_chance / turn_scale,
		roundi(max_steps_until_turn * turn_scale),
		walkers_can_u_turn
	)
	walker.changed_direction.connect(_on_walker_turned)
	walkers.append(walker)


func _on_walker_turned(cell: Vector2i) -> void:
	if randf() >= room_chance:
		return

	var min_distance_sq := min_room_spacing * min_room_spacing
	for room in rooms:
		if (room.center - cell).length_squared() < min_distance_sq:
			return

	_create_room(cell)


## A room of [param size] tiles, or a random size if [param size] is zero.
func _create_room(center: Vector2i, size := Vector2i.ZERO) -> Room:
	if size == Vector2i.ZERO:
		size = Vector2i(
			randi_range(min_room_size_x, max_room_size_x),
			randi_range(min_room_size_y, max_room_size_y)
		)
	var room := Room.new(center, size)
	rooms.append(room)
	for cell in _rect_cells(room.rect):
		_set_floor(cell)
	return room


## Carves a path_width x path_width square with [param cell] in it. Sweeping that
## along a walker's route gives a path path_width tiles wide. (For an even width
## the square extends one tile further right and down.)
func _carve_path(cell: Vector2i) -> void:
	var before := (path_width - 1) >> 1  # tiles to the left and above: 0, 0, 1 for widths 1, 2, 3
	for y in path_width:
		for x in path_width:
			_set_floor(cell + Vector2i(x - before, y - before))


## Rounds off the carved floor. Fill and erode are both safe for connectivity:
## filling only adds floor, and erosion removes one tile at a time, only when
## the floor around it still connects without it.
func _smooth_floors() -> void:
	for _pass in smoothing_passes:
		_smooth_fill()
		_smooth_erode()


## Rock tiles that are mostly surrounded by floor become floor.
func _smooth_fill() -> void:
	var floor_neighbors := {}  # rock cell -> how many of its 8 neighbours are floor
	for cell in floor_cells:
		for dir in RING:
			var next: Vector2i = cell + dir
			if not floor_cells.has(next):
				floor_neighbors[next] = floor_neighbors.get(next, 0) + 1

	for cell in floor_neighbors:
		if floor_neighbors[cell] >= SMOOTH_FILL_MIN_NEIGHBORS:
			_set_floor(cell)


## Floor tiles that stick out (few floor neighbours) are removed.
func _smooth_erode() -> void:
	# Shuffled so the result doesn't favour one corner of the map.
	var cells: Array = floor_cells.keys()
	cells.shuffle()

	for cell in cells:
		if start_room.rect.has_point(cell):
			continue
		if _count_floor_neighbors(cell) > SMOOTH_ERODE_MAX_NEIGHBORS:
			continue
		if not _is_removable(cell):
			continue
		floor_cells.erase(cell)
		tilemap.erase_cell(cell)


func _count_floor_neighbors(cell: Vector2i) -> int:
	var count := 0
	for dir in RING:
		if floor_cells.has(cell + dir):
			count += 1
	return count


## True if taking [param cell] away leaves the floor around it connected. Its
## edge neighbours (up, right, down, left) must all lie in one unbroken run of
## floor going around the 8 tiles that surround it: any path that went through
## the cell can then go around instead.
func _is_removable(cell: Vector2i) -> bool:
	var is_floor: Array[bool] = []
	for dir in RING:
		is_floor.append(floor_cells.has(cell + dir))

	var gap := is_floor.find(false)
	if gap == -1:
		return true  # floor all the way round

	var runs_with_edge_neighbor := 0
	var in_run := false
	var run_has_edge_neighbor := false
	for step in range(1, 9):  # walk once around the ring, starting just after a gap
		var i := (gap + step) % 8
		if is_floor[i]:
			in_run = true
			if i % 2 == 0:
				run_has_edge_neighbor = true
		else:
			if in_run and run_has_edge_neighbor:
				runs_with_edge_neighbor += 1
			in_run = false
			run_has_edge_neighbor = false
	return runs_with_edge_neighbor <= 1


func _set_floor(cell: Vector2i) -> void:
	if floor_cells.has(cell):
		return
	floor_cells[cell] = true
	tilemap.set_cell(cell, Tile.GROUND, Vector2i(randi_range(0, 2), 0))


# ---------------------------------------------------------------------------
# Step 2: overlay noise
# ---------------------------------------------------------------------------

func _create_overlay() -> void:
	overlay_noise = _make_noise(OVERLAY_NOISE_FREQUENCY)
	for cell in floor_cells:
		_apply_overlay(cell)


func _apply_overlay(cell: Vector2i) -> void:
	if overlay_noise.get_noise_2d(cell.x, cell.y) > OVERLAY_NOISE_THRESHOLD:
		tilemap.set_cell(cell, Tile.GROUND, Vector2i(0, 1))


func _make_noise(frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	noise.frequency = frequency
	noise.seed = randi()
	return noise


# ---------------------------------------------------------------------------
# Step 3: prefab rooms and validation
# ---------------------------------------------------------------------------

func _place_prefab_rooms() -> void:
	if room_textures.is_empty() or texture_room_amount <= 0:
		return

	var candidates: Array[Vector2i] = tilemap.get_used_cells_by_id(Tile.GROUND)
	candidates.shuffle()

	for i in texture_room_amount:
		var texture: Texture2D = room_textures.pick_random()
		if texture == null:
			continue

		var center = _find_prefab_center(texture, candidates)
		if center == null:
			push_warning("LevelGenerator: found no spot for prefab room %d of %d." % [i + 1, texture_room_amount])
			continue

		var instancer := MAP_TEXTURE_INSTANCER_SCENE.instantiate() as MapTextureInstancer
		instancer.texture = texture
		instancer.stamp(tilemap, overlay_layer, center)
		prefab_instancers.append(instancer)
		prefab_footprints.append(MapTextureInstancer.get_footprint(texture, center))


## First candidate whose whole footprint (plus margin) stays clear of the start
## room and of the other prefabs. Returns null if there is none.
func _find_prefab_center(texture: Texture2D, candidates: Array[Vector2i]) -> Variant:
	for cell in candidates:
		var padded := MapTextureInstancer.get_footprint(texture, cell).grow(texture_room_margin)
		if padded.intersects(start_room.rect):
			continue
		if _rect_hits_prefab(padded, 0):
			continue
		return cell
	return null


## True if every part of the level is still connected to the start room.
## Also fills reach_distance, which the end-room choice uses afterwards.
func _validate_layout() -> bool:
	reach_distance = _flood_fill(start_room.center)

	var walkable_total := 0
	for cell in tilemap.get_used_cells():
		if _is_walkable(cell):
			walkable_total += 1
	if walkable_total == 0:
		return false

	var reachable_fraction := float(reach_distance.size()) / float(walkable_total)
	if reachable_fraction < min_reachable_fraction:
		_log("only %.0f%% of the floor is reachable" % (reachable_fraction * 100.0))
		return false

	for footprint in prefab_footprints:
		if not _footprint_is_reachable(footprint):
			_log("a prefab room is unreachable")
			return false

	return true


## Breadth-first search over walkable tiles. Returns cell -> steps from start.
func _flood_fill(start: Vector2i) -> Dictionary:
	var distance := {start: 0}
	var queue: Array[Vector2i] = [start]
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for dir in CARDINALS:
			var next: Vector2i = cell + dir
			if not distance.has(next) and _is_walkable(next):
				distance[next] = distance[cell] + 1
				queue.append(next)
	return distance


## Floor that a prefab cut off from the start room becomes solid rock instead of
## an unreachable pocket. Cells under a prefab are left alone.
func _fill_unreachable_floor() -> void:
	for cell in floor_cells.keys():
		if reach_distance.has(cell) or _cell_in_prefab(cell, 0):
			continue
		tilemap.erase_cell(cell)
		floor_cells.erase(cell)


func _is_walkable(cell: Vector2i) -> bool:
	return tilemap.get_cell_source_id(cell) in walkable_tile_ids


func _footprint_is_reachable(footprint: Rect2i) -> bool:
	for y in range(footprint.position.y, footprint.end.y):
		for x in range(footprint.position.x, footprint.end.x):
			if reach_distance.has(Vector2i(x, y)):
				return true
	return false


func _rect_hits_prefab(rect: Rect2i, margin: int) -> bool:
	for footprint in prefab_footprints:
		if rect.intersects(footprint.grow(margin)):
			return true
	return false


func _cell_in_prefab(cell: Vector2i, margin: int) -> bool:
	for footprint in prefab_footprints:
		if footprint.grow(margin).has_point(cell):
			return true
	return false


func _spawn_prefab_objects() -> void:
	for instancer in prefab_instancers:
		instancer.spawn_objects(base_layer)
		instancer.queue_free()
	prefab_instancers.clear()


# ---------------------------------------------------------------------------
# Secret rooms
# ---------------------------------------------------------------------------

func _carve_secret_rooms() -> void:
	secret_cells.clear()
	secret_reward_cells.clear()
	if secret_room_amount <= 0:
		return

	var free := _secret_free_cells()
	for i in secret_room_amount:
		var center = _find_secret_center(free)
		if center == null:
			push_warning("LevelGenerator: found no space for secret room %d of %d." % [i + 1, secret_room_amount])
			break

		var area := Rect2i(center - secret_room_size / 2, secret_room_size)
		_carve_secret_room(center, area)
		# Keep the next room (and its rock wall) away from this one.
		for cell in _rect_cells(area.grow(secret_rock_thickness)):
			free.erase(cell)


## Rock inside the bedrock bounds that is at least secret_rock_thickness tiles
## away from anything in the main level (floor, prefabs, everything placed so far).
func _secret_free_cells() -> Dictionary:
	# One tile short of the ceiling edge so a rock ring always stays before bedrock.
	var bounds := tilemap.get_used_rect().grow(CEILING_PADDING - 1)

	var depth := {}
	var queue: Array[Vector2i] = []
	for cell in tilemap.get_used_cells():
		depth[cell] = 0
		queue.append(cell)

	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		if depth[cell] >= secret_rock_thickness:
			continue
		for dir in RING:
			var next: Vector2i = cell + dir
			if not depth.has(next):
				depth[next] = depth[cell] + 1
				queue.append(next)

	var free := {}
	for cell in _rect_cells(bounds):
		if not depth.has(cell):
			free[cell] = true
	return free


## A cell whose whole room area is free rock. Null if there's no such spot.
func _find_secret_center(free: Dictionary) -> Variant:
	var candidates: Array = free.keys()
	candidates.shuffle()
	for cell in candidates:
		var area := Rect2i(cell - secret_room_size / 2, secret_room_size)
		var fits := true
		for c in _rect_cells(area):
			if not free.has(c):
				fits = false
				break
		if fits:
			return cell
	return null


func _carve_secret_room(center: Vector2i, area: Rect2i) -> void:
	var cells: Array[Vector2i] = []

	# A 3x3 vault in the middle, then a walker wanders out from it.
	for cell in _rect_cells(Rect2i(center - Vector2i.ONE, Vector2i(3, 3))):
		_set_secret_floor(cell, cells)

	var walker := Walker.new(center, 0.3, 3, false)
	var steps := 0
	while cells.size() < secret_room_tiles and steps < secret_room_tiles * 20:
		steps += 1
		var before := walker.position
		var next := walker.walk()
		if not area.has_point(next):
			# Never leave the reserved area, so it can't touch the main level.
			walker.position = before
			walker.change_direction()
			continue
		_set_secret_floor(next, cells)

	secret_reward_cells.append(center)


func _set_secret_floor(cell: Vector2i, cells: Array[Vector2i]) -> void:
	if secret_cells.has(cell):
		return
	secret_cells[cell] = true
	cells.append(cell)
	tilemap.set_cell(cell, Tile.GROUND, Vector2i(randi_range(0, 2), 0))
	_apply_overlay(cell)


# ---------------------------------------------------------------------------
# Step 4: end room
# ---------------------------------------------------------------------------

## The start room holds the teleporter. The generator goes in the room that takes
## the longest to walk to; that room is enlarged to [member end_room_size] first.
## Both objects sit in the middle of their room.
func _choose_end_room() -> void:
	var teleporter_solid := teleporter_is_solid
	teleporter_rect = _centered_footprint(start_room.rect, teleporter_size)
	if teleporter_solid and not _footprint_is_usable(teleporter_rect, true):
		push_warning("LevelGenerator: a solid teleporter would block the start room's exits; treating it as non-solid.")
		teleporter_solid = false
	_claim_object(start_room, teleporter_rect, teleporter_solid)

	end_room = null
	var candidates := _rooms_farthest_first()
	for prefab_margin in [texture_room_margin, 0]:
		for room in candidates:
			if _try_make_end_room(room, prefab_margin):
				break
		if end_room != null:
			break

	if end_room == null:
		# Nothing fits cleanly. Use the farthest room anyway and say so.
		push_warning("LevelGenerator: no room can hold the generator without blocking a path (seed %d)." % current_seed)
		end_room = candidates[0] if not candidates.is_empty() else start_room
		generator_rect = _centered_footprint(Rect2i(end_room.center - end_room_size / 2, end_room_size), generator_size)
		# It may cut part of the level off, but don't let that stop everything else
		# from being placed: leave it out of solid_cells.
		_claim_object(end_room, generator_rect, false)
		return

	_claim_object(end_room, generator_rect, true)


## Reachable rooms (not the start room), farthest walk first.
func _rooms_farthest_first() -> Array[Room]:
	var result: Array[Room] = []
	for room in rooms:
		if room != start_room and reach_distance.has(room.center):
			result.append(room)

	result.sort_custom(func(a: Room, b: Room) -> bool:
		return reach_distance[a.center] > reach_distance[b.center])
	return result


## Enlarges [param room] to the end room size and puts the generator in its
## middle. Returns false (leaving the level as it was) if that isn't possible:
## the bigger room would run into a prefab or the start room, or the generator
## would block a path.
func _try_make_end_room(room: Room, prefab_margin: int) -> bool:
	var wanted := Rect2i(room.center - end_room_size / 2, end_room_size)
	var full := wanted.merge(room.rect)
	if full.intersects(start_room.rect.grow(1)) or _rect_hits_prefab(full, prefab_margin):
		return false

	var previous_reach := reach_distance
	var carved: Array[Vector2i] = []
	for cell in _rect_cells(full):
		if not floor_cells.has(cell):
			_set_floor(cell)
			carved.append(cell)
	reach_distance = _flood_fill(start_room.center)

	var rect := _centered_footprint(wanted, generator_size)
	if _footprint_is_usable(rect, true):
		room.rect = full
		generator_rect = rect
		end_room = room
		for cell in carved:
			_apply_overlay(cell)
		return true

	# Undo.
	for cell in carved:
		tilemap.erase_cell(cell)
		floor_cells.erase(cell)
	reach_distance = previous_reach
	return false


## A rectangle of [param size] tiles in the middle of [param rect].
func _centered_footprint(rect: Rect2i, size: Vector2i) -> Rect2i:
	return Rect2i(rect.position + (rect.size - size) / 2, size)


## All ground, nothing else there, and (if solid) not blocking any path.
func _footprint_is_usable(rect: Rect2i, is_solid: bool) -> bool:
	for cell in _rect_cells(rect):
		if tilemap.get_cell_source_id(cell) != Tile.GROUND:
			return false
		if solid_cells.has(cell):
			return false
	return not (is_solid and _footprint_cuts_level(rect))


func _claim_object(room: Room, rect: Rect2i, is_solid: bool) -> void:
	_reserve_room(room)
	_reserve_rect(rect)
	used_positions.append(room.center)
	used_positions.append(rect.position + rect.size / 2)
	if is_solid:
		for cell in _rect_cells(rect):
			solid_cells[cell] = true


func _reserve_room(room: Room) -> void:
	_reserve_rect(room.rect)


func _reserve_rect(rect: Rect2i) -> void:
	for cell in _rect_cells(rect):
		reserved_cells[cell] = true


# ---------------------------------------------------------------------------
# Step 5: crate / prop / spawner positions
# ---------------------------------------------------------------------------

func _find_tile_positions() -> void:
	# Order matters: each category keeps its distance from the ones before it.
	# The car is the biggest thing, so it gets first pick of the spots.
	car_positions = _pick_positions("car", 1, car_size, CAR_SPACING, 8, true)
	crate_positions = _pick_positions("crates", crate_amount if crate_list != null else 0, crate_size, 8, 0, true)
	# Decide what each crate is now, so _shop_energy_cost() knows the energy budget
	# before the minerals are scattered.
	crate_items.clear()
	for i in crate_positions.size():
		crate_items.append(crate_list.spawn_table.pick_item())
	prop_positions = _pick_positions("props", prop_amount, prop_size, 4, 1, true)
	spawner_positions = _pick_positions("spawners", spawner_amount, Vector2i.ONE, 3, 8, false)


## Picks up to [param amount] footprints of [param size] tiles. Returns the
## top-left cell of each. A footprint is valid if
##  - every tile in it is reachable ground that nothing else uses,
##  - it is at least [param min_spacing] tiles from everything placed so far,
##  - at most [param max_wall_neighbors] of the tiles around it are not ground,
##  - it is not in a prefab room, and
##  - if [param is_solid]: blocking it doesn't cut any part of the level off.
## If there aren't enough valid spots, the spacing is relaxed step by step.
func _pick_positions(
	label: String, amount: int, size: Vector2i, min_spacing: int, max_wall_neighbors: int, is_solid: bool
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if amount <= 0:
		return result

	# Shuffled so picks are spread over the map instead of bunching up in
	# whatever order the tilemap happens to list its cells.
	var candidates: Array[Vector2i] = tilemap.get_used_cells_by_id(Tile.GROUND)
	candidates.shuffle()

	# Spots that would cut the level apart. Solid objects only ever add to
	# what's blocked, so once a spot is bad it stays bad.
	var cuts_level := {}

	var spacing := min_spacing
	while true:
		for anchor in candidates:
			if result.size() >= amount:
				break
			var rect := Rect2i(anchor, size)
			if cuts_level.has(anchor) or not _is_valid_footprint(rect, spacing, max_wall_neighbors):
				continue
			if is_solid and _footprint_cuts_level(rect):
				cuts_level[anchor] = true
				continue

			result.append(anchor)
			used_positions.append(rect.position + rect.size / 2)
			for cell in _rect_cells(rect):
				reserved_cells[cell] = true
				if is_solid:
					solid_cells[cell] = true

		if result.size() >= amount or spacing <= MIN_RELAXED_SPACING:
			break
		spacing -= 1

	if result.size() < amount:
		push_warning("LevelGenerator: placed only %d of %d %s." % [result.size(), amount, label])
	_log("%s: %d/%d" % [label, result.size(), amount])
	return result


func _is_valid_footprint(rect: Rect2i, spacing: int, max_wall_neighbors: int) -> bool:
	for cell in _rect_cells(rect):
		if reserved_cells.has(cell) or not reach_distance.has(cell):
			return false
		if tilemap.get_cell_source_id(cell) != Tile.GROUND:
			return false
	if _rect_hits_prefab(rect, 1):
		return false
	if not _is_far_enough(rect.position + rect.size / 2, spacing):
		return false
	return _count_non_ground_around(rect) <= max_wall_neighbors


func _is_far_enough(cell: Vector2i, spacing: int) -> bool:
	var min_distance_sq := spacing * spacing
	for other in used_positions:
		if (cell - other).length_squared() < min_distance_sq:
			return false
	return true


## How many of the tiles in the one-tile ring around [param rect] are not ground.
## For a 1x1 rect that's the 8 neighbours.
func _count_non_ground_around(rect: Rect2i) -> int:
	var count := 0
	for cell in _rect_cells(rect.grow(1)):
		if rect.has_point(cell):
			continue
		if tilemap.get_cell_source_id(cell) != Tile.GROUND:
			count += 1
	return count


## True if blocking [param rect] (on top of the solid objects already placed)
## would leave some walkable tile unreachable from the start room.
func _footprint_cuts_level(rect: Rect2i) -> bool:
	var blocked := solid_cells.duplicate()
	for cell in _rect_cells(rect):
		blocked[cell] = true

	# Flood fill over the tiles that were reachable before any objects, skipping
	# blocked ones. Dictionary lookups only, so it is cheap to repeat.
	var seen := {start_room.center: true}
	var queue: Array[Vector2i] = [start_room.center]
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for dir in CARDINALS:
			var next: Vector2i = cell + dir
			if not seen.has(next) and not blocked.has(next) and reach_distance.has(next):
				seen[next] = true
				queue.append(next)

	for cell in reach_distance:
		if not seen.has(cell) and not blocked.has(cell):
			return true
	return false


func _rect_cells(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells


# ---------------------------------------------------------------------------
# Step 6: ceiling, walls, ore
# ---------------------------------------------------------------------------

func _create_ceiling(tile_type: int, padding: int) -> void:
	var rect := tilemap.get_used_rect()
	for x in range(rect.position.x - padding, rect.end.x + padding):
		for y in range(rect.position.y - padding, rect.end.y + padding):
			var cell := Vector2i(x, y)
			if tilemap.get_cell_source_id(cell) != Tile.NONE:
				continue
			tilemap.set_cell(cell, tile_type, Vector2i.ZERO)


## Turns the bottom row of each ceiling mass into a wall tile.
func _create_walls(ceiling_type: int, wall_type: int) -> void:
	for tile in tilemap.get_used_cells_by_id(ceiling_type):
		var below := tilemap.get_neighbor_cell(tile, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE)
		var below_id := tilemap.get_cell_source_id(below)
		if below_id == ceiling_type or below_id == wall_type:
			continue

		tilemap.set_cell(tile, wall_type, Vector2i.ZERO)
		overlay_layer.set_cell(tile, ceiling_type, Vector2i(0, 1))
		overlay_layer.set_cell(below, Tile.SHADOW, Vector2i.ZERO)


## Energy first, so it gets the pick of the rock and the shop budget is always met.
## Ore then goes into whatever rock is left, away from the energy.
func _scatter_minerals() -> void:
	var shop_cost := _shop_energy_cost()
	var energy_target := maxi(ceili(shop_cost * energy_surplus), min_energy_tiles)
	_log("shops cost %d energy" % shop_cost)

	# Every vein starts on rock that touches the floor (depth 1), so there is always
	# energy that needs no digging. From there it grows into the rock in any
	# direction, following the noise. Starting points are random so the energy is
	# spread evenly over the map instead of bunching up on the noise peaks.
	var energy_cells := _scatter_in_rock(
		"energy", energy_target, ENERGY_ATLAS_X, energy_vein_size, energy_min_spacing,
		_rock_candidates(1), _rock_candidates(maxi(energy_max_depth, 1)),
		_make_vein_noise(energy_noise_frequency), false
	)

	# Built after the energy is placed, so energy tiles are no longer plain rock.
	# Ore starts on the noise peaks, so it forms a few big natural clusters.
	var ore_rock := _rock_candidates(ore_max_depth)
	_block_around(energy_cells, ore_energy_clearance, ore_rock)
	_scatter_in_rock(
		"ore", ore_amount, ORE_ATLAS_X, ore_vein_size, ore_min_spacing,
		ore_rock, ore_rock, _make_vein_noise(ore_noise_frequency), true
	)


## Noise for growing veins. Two octaves roughen the edges so veins don't look like
## smooth blobs.
func _make_vein_noise(frequency: float) -> FastNoiseLite:
	var noise := _make_noise(frequency)
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = 2
	return noise


## Total energy the crate shops on this level charge.
func _shop_energy_cost() -> int:
	var total := 0
	for item in crate_items:
		total += item.energy_cost
	return total


## Hides [param target] tiles of a mineral in the rock, as veins whose starting
## points keep their distance from each other. That spreads the mineral over the
## whole map, so the player has to explore to collect it all. If there isn't room,
## the spacing is relaxed step by step.
##
## [param starts] holds the tiles a vein may start on and [param free_rock] the tiles
## it may grow into (both are cell -> true; they may be the same dictionary). Veins
## grow along [param noise]. If [param starts_follow_noise] is on, the highest noise
## values are tried first as starting points, otherwise they are random.
## Placed tiles are removed from [param free_rock]. Returns the tiles placed.
func _scatter_in_rock(
	label: String, target: int, atlas_x: int, vein_size: Vector2i, min_spacing: int,
	starts: Dictionary, free_rock: Dictionary, noise: FastNoiseLite, starts_follow_noise: bool
) -> Array[Vector2i]:
	var placed: Array[Vector2i] = []
	if target <= 0:
		return placed

	var order: Array = starts.keys()
	if starts_follow_noise:
		order.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
			return noise.get_noise_2d(a.x, a.y) > noise.get_noise_2d(b.x, b.y))
	else:
		order.shuffle()

	var low := maxi(vein_size.x, 1)
	var high := maxi(vein_size.y, low)
	var seeds: Array[Vector2i] = []
	var spacing := min_spacing
	while placed.size() < target and spacing >= 0:
		for cell in order:
			if placed.size() >= target:
				break
			if not free_rock.has(cell) or not _far_from_all(cell, seeds, spacing):
				continue
			seeds.append(cell)
			var wanted := mini(randi_range(low, high), target - placed.size())
			placed.append_array(_grow_vein(cell, wanted, atlas_x, free_rock, noise))
		spacing -= 1

	if placed.size() < target:
		push_warning("LevelGenerator: placed only %d of %d %s tiles (seed %d)." % [
			placed.size(), target, label, current_seed
		])
	_log("%s: %d/%d" % [label, placed.size(), target])
	return placed


## Plain ceiling and wall tiles (no mineral yet) that are at most [param max_depth]
## steps from the floor. A flood fill starts at every ground tile and spreads
## through rock, so the depth is the number of tiles the player has to dig through.
func _rock_candidates(max_depth: int) -> Dictionary:
	var depth := {}
	var queue: Array[Vector2i] = []
	for cell in tilemap.get_used_cells_by_id(Tile.GROUND):
		depth[cell] = 0
		queue.append(cell)

	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		if depth[cell] >= max_depth:
			continue
		for dir in CARDINALS:
			var next: Vector2i = cell + dir
			if depth.has(next):
				continue
			var id := tilemap.get_cell_source_id(next)
			if id != Tile.CEILING and id != Tile.WALL:
				continue
			depth[next] = depth[cell] + 1
			queue.append(next)

	var result := {}
	for cell in depth:
		# Atlas column 0 is plain rock. Anything else already holds a mineral.
		if depth[cell] > 0 and tilemap.get_cell_atlas_coords(cell).x == 0:
			result[cell] = true
	return result


## Removes every rock tile closer than [param radius] tiles to one of [param cells].
func _block_around(cells: Array[Vector2i], radius: int, free_rock: Dictionary) -> void:
	if radius <= 0:
		return

	var radius_sq := radius * radius
	for cell in cells:
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if x * x + y * y < radius_sq:
					free_rock.erase(cell + Vector2i(x, y))


## Grows up to [param size] connected rock tiles from [param start]. Best-first:
## it always claims the neighbouring tile with the highest noise value next, so
## the vein follows the shape of the noise instead of a circle, in any direction.
## Placed tiles are removed from [param free_rock]. Returns them.
func _grow_vein(
	start: Vector2i, size: int, atlas_x: int, free_rock: Dictionary, noise: FastNoiseLite
) -> Array[Vector2i]:
	var vein: Array[Vector2i] = []
	var frontier := {start: true}
	while vein.size() < size and not frontier.is_empty():
		var best: Vector2i = start
		var best_value := -INF
		for cell in frontier:
			var value := noise.get_noise_2d(cell.x, cell.y)
			if value > best_value:
				best_value = value
				best = cell

		frontier.erase(best)
		_set_mineral(best, atlas_x)
		free_rock.erase(best)
		vein.append(best)
		for dir in CARDINALS:
			var next: Vector2i = best + dir
			if free_rock.has(next):
				frontier[next] = true
	return vein


func _far_from_all(cell: Vector2i, points: Array[Vector2i], spacing: int) -> bool:
	var min_distance_sq := spacing * spacing
	for other in points:
		if (cell - other).length_squared() < min_distance_sq:
			return false
	return true


## Ceilings swap to the mineral's atlas column. Walls do too, plus the matching cap
## on the overlay layer (row 1) so the top of the wall looks right.
func _set_mineral(cell: Vector2i, atlas_x: int) -> void:
	match tilemap.get_cell_source_id(cell):
		Tile.CEILING:
			tilemap.set_cell(cell, Tile.CEILING, Vector2i(atlas_x, 0))
		Tile.WALL:
			tilemap.set_cell(cell, Tile.WALL, Vector2i(atlas_x, 0))
			overlay_layer.set_cell(cell, Tile.CEILING, Vector2i(atlas_x, 1))


# ---------------------------------------------------------------------------
# Step 7: spawning
# ---------------------------------------------------------------------------

func _populate_level() -> void:
	# The player starts standing on the teleporter.
	var start_position := _rect_to_world(teleporter_rect)
	create_instance(PLAYER_SCENE, start_position)
	
	var camera = get_viewport().get_camera_2d() as PlayerCamera
	var limits := tilemap.get_used_rect()
	camera.set_limits(limits)
	
	create_instance(TELEPORTER_SCENE, start_position)

	create_instance(GENERATOR_SCENE, _rect_to_world(generator_rect))

	for anchor in car_positions:
		create_instance(CAR_SCENE, _rect_to_world(Rect2i(anchor, car_size)))

	for i in crate_items.size():
		var item := crate_items[i]
		var crate := create_instance(item.scene, _rect_to_world(Rect2i(crate_positions[i], crate_size)))
		# The item is the single source of truth for the price.
		if "required_energy" in crate:
			crate.set("required_energy", item.energy_cost)

	for cell in spawner_positions:
		var spawner := create_instance(SPAWNER_SCENE, _cell_to_world(cell))
		enemy_manager.add_spawner(spawner)
		if dust_scene != null:
			create_instance(dust_scene, _cell_to_world(cell))

	for anchor in prop_positions:
		create_instance(prop_list.spawn_table.pick_item(), _rect_to_world(Rect2i(anchor, prop_size)))
	
	if secret_reward_scene != null:
		for cell in secret_reward_cells:
			create_instance(secret_reward_scene, _cell_to_world(cell))


func create_instance(scene: PackedScene, world_position: Vector2) -> Node2D:
	var instance := scene.instantiate() as Node2D
	instance.position = world_position
	base_layer.add_child(instance)
	return instance


## World position of the middle of a tile.
func _cell_to_world(cell: Vector2i) -> Vector2:
	return tilemap.to_global(tilemap.map_to_local(cell))


## World position of the true middle of a rectangle of tiles. A sprite centered
## on this point covers exactly those tiles, for even and odd sizes alike.
func _rect_to_world(rect: Rect2i) -> Vector2:
	var first_cell := tilemap.map_to_local(rect.position)
	var last_cell := tilemap.map_to_local(rect.end - Vector2i.ONE)
	return tilemap.to_global((first_cell + last_cell) / 2.0)


func _log(message: String) -> void:
	if debug_log:
		print("[LevelGenerator] ", message)

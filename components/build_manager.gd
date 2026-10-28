@icon("res://addons/at-icons/node2d/hammer.svg")
extends Node2D
class_name BuildManager

@export var build_range : float = 48.0

const GROUND_SOURCE := 0
const CHARACTER_MASK := 2 | 4 # player + enemy layers

var stats : PlayerStats
var inventory : WeaponInventoryComponent
var tilemap : TileMap
var base_layer : Node2D
var grid : PathfindingGrid

var active : bool = false
var index : int = 0
var valid : bool = false

var ghost := Sprite2D.new()
var tile_shape := RectangleShape2D.new()


func _ready():
	tile_shape.size = Vector2(12, 12)
	ghost.top_level = true
	ghost.z_index = 11
	ghost.hide()
	add_child(ghost)
	set_physics_process(false) # stays off until setup (e.g. in the ship hub)


func setup(new_stats : PlayerStats, new_inventory : WeaponInventoryComponent):
	stats = new_stats
	inventory = new_inventory
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")
	set_physics_process(true)


func _physics_process(_delta):
	if Input.is_action_just_pressed("build_mode"):
		set_active(not active)
	
	if not active:
		return
	
	if Input.is_action_just_released("scroll_down"):
		select(index + 1)
	if Input.is_action_just_released("scroll_up"):
		select(index - 1)
	
	update_ghost()
	
	if Input.is_action_just_pressed("attack") and valid:
		place()
	if Input.is_action_just_pressed("alt_attack"):
		set_active(false)


func set_active(value : bool):
	if value and stats.buildings.is_empty():
		return
	
	active = value
	ghost.visible = value
	inventory.set_suspended(value)
	GameEvents.build_mode_changed.emit(value)
	if value:
		select(index)


func select(new_index : int):
	index = wrapi(new_index, 0, stats.buildings.size())
	GameEvents.building_selected.emit(stats.buildings[index])


func update_ghost():
	var item := stats.buildings[index]
	var aim := get_global_mouse_position()
	if GamepadManager.using_gamepad:
		aim = global_position + GamepadManager.get_aim_direction()
	
	aim = global_position + (aim - global_position).limit_length(build_range)
	var tile := tilemap.local_to_map(tilemap.to_local(aim))
	
	valid = can_place(tile, item)
	ghost.texture = item.icon
	ghost.global_position = tilemap.to_global(tilemap.map_to_local(tile))
	ghost.modulate = Color(0.3, 1, 0.4, 0.6) if valid else Color(1, 0.3, 0.3, 0.6)


func can_place(tile : Vector2i, item : BuildingItem) -> bool:
	if stats.ore < item.ore_cost:
		return false
	if tilemap.get_cell_source_id(0, tile) != GROUND_SOURCE:
		return false
	if Building.occupied.has(tile):
		return false
	
	# props, crates, shops etc. already mark their tile solid in the A* grid
	if not grid:
		grid = get_tree().get_first_node_in_group("pathfinding")
	if grid and grid.astar_grid.is_in_boundsv(tile) and grid.astar_grid.is_point_solid(tile):
		return false
	
	# don't build on top of the player or enemies
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = tile_shape
	query.transform = Transform2D(0, tilemap.to_global(tilemap.map_to_local(tile)))
	query.collision_mask = CHARACTER_MASK
	return get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()


func place():
	var item := stats.buildings[index]
	if not stats.spend_ore(item.ore_cost):
		return
	
	var building := item.building_scene.instantiate() as Node2D
	building.position = ghost.global_position # set before add_child so Building._ready sees it
	base_layer.add_child(building) # base_layer sits at the origin

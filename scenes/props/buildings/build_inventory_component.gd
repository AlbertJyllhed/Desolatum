extends InventoryComponent
class_name BuildIndicator

@export var buildings : Array[BuildingItem]

@onready var sprite : Sprite2D = $BuildingSprite
@onready var tile_checker_area : Area2D = $TileCheckerArea
@onready var collision_shape : CollisionShape2D = $TileCheckerArea/CollisionShape2D

var stats : PlayerStats = preload("res://resources/Data/player_stats.tres")

var tilemap : TileMap
var base_layer : Node2D

#var building_id : String = ""
var energy_cost : int
var ore_cost : int


func _ready():
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")
	
	max_index = buildings.size() - 1
	modulate.a = 0.5
	set_building(buildings[index])


func set_building(building : BuildingItem):
	sprite.texture = building.texture
	tile_checker_area.position = sprite.position + building.get_size()
	collision_shape.shape.extents = building.get_size() - Vector2.ONE
	#building_id = building.id
	energy_cost = building.energy_cost
	ore_cost = building.ore_cost


func next_slot():
	super.next_slot()
	set_building(buildings[index])
	#building_id = buildings[index].id
	#print(building_id)


func prev_slot():
	super.prev_slot()
	set_building(buildings[index])
	#building_id = buildings[index].id
	#print(building_id)


func can_place() -> bool:
	if tile_checker_area.has_overlapping_bodies() \
	or stats.energy < energy_cost or stats.ore < ore_cost:
		modulate = Color.RED
		return false
	
	modulate = Color.GREEN
	return true


func _physics_process(_delta):
	if deactivated:
		return
	
	var mouse_tile = tilemap.local_to_map(get_global_mouse_position())
	var local_pos = tilemap.map_to_local(mouse_tile)
	var global_pos = tilemap.to_global(local_pos)
	var offset = Vector2(8, 8)
	global_position = global_pos - offset
	
	if not can_place():
		return
	
	if Input.is_action_just_pressed("attack"):
		stats.energy -= energy_cost
		stats.ore -= ore_cost
		GameEvents.energy_updated.emit(stats.energy)
		GameEvents.ore_updated.emit(stats.ore)
		
		var building_instance = buildings[index].building_scene.instantiate()
		base_layer.add_child(building_instance)
		building_instance.global_position = global_pos

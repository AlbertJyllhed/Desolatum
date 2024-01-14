extends InventoryComponent
class_name BuildIndicator

@export var buildings : Array[BuildingItem]

@onready var sprite : Sprite2D = $BuildingSprite
@onready var tile_checker_area : Area2D = $TileCheckerArea
@onready var collision_shape : CollisionShape2D = $TileCheckerArea/CollisionShape2D

var tilemap : TileMap
var base_layer : Node2D

var buildings_placed : Dictionary = {
	"turret" : 0,
	"mining_light" : 0,
	"mine" : 0
}
var building_id = ""


func _ready():
	GameEvents.item_picked_up.connect(on_item_picked_up)
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")
	
	max_index = buildings.size() - 1
	set_building(buildings[index])


func set_building(building : BuildingItem):
	sprite.texture = building.texture
	tile_checker_area.position = sprite.position + building.get_size()
	collision_shape.shape.extents = building.get_size() - Vector2.ONE
	building_id = building.id


func next_slot():
	super.next_slot()
	set_building(buildings[index])


func prev_slot():
	super.prev_slot()
	set_building(buildings[index])


func can_place() -> bool:
	if tile_checker_area.has_overlapping_bodies() or \
	buildings_placed[building_id] == buildings[index].limit:
		modulate = Color.RED
		modulate.a = 0.5
		return false
	
	modulate = Color.GREEN
	modulate.a = 0.5
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
		var building_instance = buildings[index].building_scene.instantiate()
		base_layer.add_child(building_instance)
		building_instance.global_position = global_pos
		building_instance.set_item(buildings[index])
		buildings_placed[building_id] = min(buildings_placed[building_id] + 1, buildings[index].limit)


func on_item_picked_up(item : Item):
	if buildings_placed.has(item.id):
		buildings_placed[item.id] = max(buildings_placed[item.id] - 1, 0)
		print(buildings_placed[item.id])

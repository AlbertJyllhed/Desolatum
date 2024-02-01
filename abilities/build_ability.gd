extends Ability

@export var ability_scene : PackedScene

@onready var pivot : Node2D = $Pivot
@onready var tile_checker_area : Area2D = $Pivot/TileCheckerArea

var tilemap : TileMap
var base_layer : Node2D
var attack_vector : Vector2


func _ready():
	super._ready()
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")


func _physics_process(delta):
	super._physics_process(delta)
	attack_vector = get_global_mouse_position()
	pivot.look_at(attack_vector)


func try_use_ability():
	if tile_checker_area.has_overlapping_bodies():
		return
	
	super.try_use_ability()


func use_ability():
	var mouse_tile = tilemap.local_to_map(tile_checker_area.global_position)
	var local_pos = tilemap.map_to_local(mouse_tile)
	var global_pos = tilemap.to_global(local_pos)
	
	var ability_instance = ability_scene.instantiate()
	base_layer.add_child(ability_instance)
	ability_instance.global_position = global_pos
	super.use_ability()

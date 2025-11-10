extends EnemyWeaponBase

@export var thorn_scene : PackedScene
@export var thorn_amount : int = 3

var player : Player
var tilemap : TileMap
var base_layer : Node2D


func _ready():
	player = get_tree().get_first_node_in_group("player")
	target_locator_ray.set_target(player)
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")


func attack(attack_vector : Vector2):
	if not is_instance_valid(player):
		return
	
	for i in thorn_amount:
		var offset = Vector2(randi_range(-32, 32), randi_range(-32, 32))
		var tile_pos = tilemap.local_to_map(player.global_position + offset)
		var local_pos = tilemap.map_to_local(tile_pos)
		var global_pos = tilemap.to_global(local_pos)
		
		var thorn_instance = thorn_scene.instantiate() as Node2D
		base_layer.add_child(thorn_instance)
		thorn_instance.global_position = global_pos

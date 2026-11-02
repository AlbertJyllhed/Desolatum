extends Area2D

@export var remove_by_position : bool = false

@onready var collision_shape : CollisionShape2D = $CollisionShape2D


func _ready():
	if not remove_by_position:
		return
	
	var map = get_tree().get_first_node_in_group("tilemap_layer") as TileMapLayer
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
			
			TileBreaker.break_tile(center + Vector2i(x, y))

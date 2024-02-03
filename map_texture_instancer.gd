extends Node2D

@export var texture : Texture2D
@export var color_instances : Array[ColorToInstance]

var image : Image
var tilemap : TileMap
var base_layer : Node2D
enum { ground = 0, ceiling = 1, wall = 2, bedrock = 3, shadow = 14, none = -1 }

var room_size_in_tiles : Vector2


func _ready():
	image = texture.get_image()
	room_size_in_tiles = image.get_size()
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")
	generate_room_tiles()


func generate_room_tiles():
	for x in image.get_width():
		for y in image.get_height():
			generate_tile(x, y)


func generate_tile(x : int, y : int):
	var pixel_color = image.get_pixel(x, y)
	if pixel_color.a == 0:
		return
	
	for color_instance in color_instances:
		if not color_instance.color.is_equal_approx(pixel_color):
			continue
		
		var tile_pos = get_tile_position(x, y)
		if color_instance.scene:
			var instance = color_instance.scene.instantiate() as Node2D
			base_layer.add_child(instance)
			instance.global_position = tile_pos * 16 + Vector2(8, 8)
		
		tilemap.set_cell(0, tile_pos, color_instance.tile_id, Vector2i.ZERO)
		return


func get_tile_position(x : int, y : int):
	var offset = Vector2(-room_size_in_tiles.x / 2, -room_size_in_tiles.y / 2)
	var final_pos = Vector2(x, y) + offset + global_position
	return final_pos

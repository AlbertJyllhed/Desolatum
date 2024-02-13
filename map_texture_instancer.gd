extends Node2D
class_name MapTextureInstancer

signal finished

@export var texture : Texture2D
@export var color_instances : Array[ColorToInstance]

var image : Image
var tilemap : TileMap
var base_layer : Node2D
var room_size_in_tiles : Vector2i


func setup():
	image = texture.get_image()
	room_size_in_tiles = image.get_size()
	tilemap = get_tree().get_first_node_in_group("tilemap_layer")
	base_layer = get_tree().get_first_node_in_group("base_layer")
	generate_room_tiles()


func generate_room_tiles():
	for x in image.get_width():
		for y in image.get_height():
			generate_tile(x, y)
	
	finished.emit()


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
			base_layer.call_deferred("add_child", instance)
			instance.global_position = tile_pos * 16 + Vector2i(8, 8)
		
		var random_x = randi_range(color_instance.min_x, color_instance.max_x)
		var random_y = randi_range(color_instance.min_y, color_instance.max_y)
		tilemap.set_cell(0, tile_pos, color_instance.tile_id, Vector2i(random_x, random_y))
		tilemap.set_cell(1, tile_pos, -1, Vector2i.ZERO)
		return


func get_tile_position(x : int, y : int):
	var offset = Vector2i(-room_size_in_tiles.x / 2, -room_size_in_tiles.y / 2)
	var global_to_map = tilemap.local_to_map(global_position)
	var final_pos = Vector2i(x, y) + offset + global_to_map
	return final_pos

extends Item
class_name BuildingItem

@export var building_scene : PackedScene
@export var texture : Texture2D
@export var energy_cost : int = 1
@export var ore_cost : int = 1


func get_size() -> Vector2:
	var size_x = texture.get_width() / 2
	var size_y = texture.get_height() / 2
	var size = Vector2(size_x, size_y)
	return size

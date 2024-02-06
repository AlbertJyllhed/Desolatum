extends Resource
class_name ColorToInstance

@export var color : Color

@export var scene : PackedScene
@export var tile_id : TileType

@export_group("Variant Settings")
@export var min_x : int
@export var max_x : int
@export var min_y : int
@export var max_y : int

enum TileType {
	ground = 0,
	ceiling = 1,
	wall = 2,
	bedrock = 3,
	ship_ground = 5,
	ship_ceiling = 7,
	shadow = 14,
	none = -1
}

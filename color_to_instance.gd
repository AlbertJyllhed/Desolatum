extends Resource
class_name ColorToInstance

@export var color : Color
@export var tile_id : TileType
@export var max_variant : int
@export var scene : PackedScene

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

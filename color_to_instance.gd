extends Resource
class_name ColorToInstance

@export var color: Color

@export var scene: PackedScene
@export var tile_id: Tiles.Id

@export_group("Variant Settings")
@export var min_x: int
@export var max_x: int
@export var min_y: int
@export var max_y: int

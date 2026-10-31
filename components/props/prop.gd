extends StaticBody2D

## How many tiles this prop covers (width x height)
@export var footprint: Vector2i = Vector2i.ONE

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow

var tiles: Array[Vector2i] = []


func _ready():
	tiles = get_covered_tiles()
	for tile in tiles:
		GameEvents.navigation_updated.emit(tile, true)
	
	if randf() < 0.5:
		return
	
	sprite.flip_h = true
	shadow.flip_h = true


func get_covered_tiles() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	# top-left corner of the footprint, in tile units
	var top_left = global_position / 16.0 - Vector2(footprint) / 2.0
	var origin = Vector2i(top_left.round())
	for y in footprint.y:
		for x in footprint.x:
			result.append(origin + Vector2i(x, y))
	
	return result


func _on_health_component_died():
	for tile in tiles:
		GameEvents.navigation_updated.emit(tile, false)

extends Node2D
class_name RockFallCluster

## A patch of floor tiles with loose rock in the ceiling above them. The
## LevelGenerator places these. When a wall or ceiling tile next to any of the
## tiles breaks, the rock starts falling on that tile and the collapse spreads
## outward one step at a time until every tile has dropped its rock. The
## cluster frees itself once all its rocks have fallen.

const MARKER_SCENE: PackedScene = preload("uid://swwht6df18ty")
## The 8 tiles around a tile. Diagonals count as "next to".
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
	Vector2i(-1, 0), Vector2i(1, 0),
	Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]

## Seconds between each step of the collapse spreading outward.
var spread_delay: float = 0.2

## Vector2i (tile) -> RockFallMarker
var _markers: Dictionary = {}
var _collapsing: bool = false


func _ready() -> void:
	GameEvents.tile_broken.connect(_on_tile_broken)


## [param cells] maps each tile to its world position (the middle of the tile).
## Call after the cluster is in the tree.
func setup(cells: Dictionary, new_spread_delay: float) -> void:
	spread_delay = new_spread_delay
	for cell: Vector2i in cells:
		var marker := MARKER_SCENE.instantiate() as RockFallMarker
		add_child(marker)
		marker.global_position = cells[cell]
		marker.tree_exited.connect(_on_marker_exited)
		_markers[cell] = marker


func _on_tile_broken(coord: Vector2i) -> void:
	if _collapsing:
		return
	for dir in NEIGHBORS:
		var cell: Vector2i = coord + dir
		if _markers.has(cell):
			_collapse(cell)
			return


## Drops the rock on [param start], then on every tile one step further out
## each spread_delay, until the whole cluster has fallen.
func _collapse(start: Vector2i) -> void:
	_collapsing = true
	var visited: Dictionary = {start: true}
	var current: Array[Vector2i] = [start]
	while not current.is_empty():
		var next: Array[Vector2i] = []
		for cell in current:
			var marker: Variant = _markers[cell]
			if is_instance_valid(marker):
				(marker as RockFallMarker).fall()
			for dir in NEIGHBORS:
				var neighbor: Vector2i = cell + dir
				if _markers.has(neighbor) and not visited.has(neighbor):
					visited[neighbor] = true
					next.append(neighbor)
		current = next
		if not current.is_empty():
			await get_tree().create_timer(spread_delay, false).timeout
			if not is_inside_tree():
				return


func _on_marker_exited() -> void:
	if is_queued_for_deletion():
		return
	# Untyped on purpose: a typed variable errors when handed a freed marker.
	for marker: Variant in _markers.values():
		if is_instance_valid(marker) and (marker as Node).is_inside_tree():
			return
	queue_free()

class_name Tiles

enum Id {
	NONE = -1,
	GROUND = 0,
	CEILING = 1,
	WALL = 2,
	BEDROCK = 3,
	SHIP_GROUND = 5,
	SHIP_WALL = 6,
	SHIP_CEILING = 7,
	SHADOW = 14,
}

const CELL_SIZE := 16
const HALF := CELL_SIZE / 2.0

static func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i((pos / CELL_SIZE).floor())

static func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE + Vector2(HALF, HALF)

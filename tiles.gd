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

const LAYER_BASE := 0
const LAYER_OVERLAY := 1
const CELL_SIZE := 16

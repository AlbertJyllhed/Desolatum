extends RefCounted
class_name Walker
## A random-walk agent. Each call to walk() moves it one cell, and it
## occasionally turns, emitting changed_direction when it does.
##
## Extends RefCounted (not Node), so there is nothing to queue_free(): a walker
## is cleaned up as soon as nothing references it any more.

## Emitted with the walker's position at the moment it turns.
signal changed_direction(position: Vector2i)

const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN]

var position := Vector2i.ZERO
var direction := Vector2i.RIGHT
var turn_chance: float = 0.25
var max_steps_until_turn: int = 4
## If false, a turn can never send the walker straight back where it came from.
## That gives longer, less blobby paths.
var allow_u_turns: bool = true
var steps_since_turn: int = 0


func _init(
	start: Vector2i,
	new_turn_chance: float,
	new_max_steps_until_turn: int,
	new_allow_u_turns: bool = true
) -> void:
	position = start
	turn_chance = new_turn_chance
	max_steps_until_turn = new_max_steps_until_turn
	allow_u_turns = new_allow_u_turns


func walk() -> Vector2i:
	if randf() <= turn_chance or steps_since_turn >= max_steps_until_turn:
		change_direction()

	position += direction
	steps_since_turn += 1
	return position


func change_direction() -> void:
	steps_since_turn = 0

	var options: Array[Vector2i] = []
	for dir in DIRECTIONS:
		if dir == direction:
			continue
		if not allow_u_turns and dir == -direction:
			continue
		options.append(dir)

	direction = options.pick_random()
	changed_direction.emit(position)

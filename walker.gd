extends Node
class_name Walker

signal changed_direction(position)

const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]

var position = Vector2.ZERO
var direction = Vector2.RIGHT
var turn_chance : float = 0.25
var max_steps_until_turn : int = 4
var steps_since_turn : int = 0


func _init(starting_position, new_turn_chance, new_steps_until_turn):
	position = starting_position
	turn_chance = new_turn_chance
	max_steps_until_turn = new_steps_until_turn


func walk():
	if randf() <= turn_chance or steps_since_turn >= max_steps_until_turn:
		change_direction()
	
	step()
	return position


func step():
	var target_position = position + direction
	steps_since_turn += 1
	position = target_position


func change_direction():
	steps_since_turn = 0
	var directions = DIRECTIONS.duplicate()
	directions.erase(direction)
	directions.shuffle()
	direction = directions.pop_front()
	changed_direction.emit(position)

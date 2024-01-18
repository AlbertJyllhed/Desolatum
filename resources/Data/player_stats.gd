extends Resource
class_name PlayerStats

#for player
var speed : float = 0
@export var base_speed : float = 80.0

#for health component
var health : int = 0
var max_health : int = 6
@export var base_health : int = 6

#for weapon component
var weapons : Array[WeaponItem]
var equipment_index : int

var energy : int = 0
var ore : int = 0


func _init():
	reset()


func reset():
	speed = base_speed
	max_health = base_health
	health = max_health
	weapons.clear()
	equipment_index = 0
	energy = 0
	ore = 0

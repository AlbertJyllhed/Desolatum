extends Resource
class_name PlayerStats

var stats : Dictionary = {
	"max_health" : 6,
	"health" : 6,
	"move_speed" : 80.0
}

var weapon_stats : Dictionary = {
	"damage" : 0,
	"max_ammo" : 0,
	"ammo" : 0,
	"reload_speed" : 0,
	"projectile_deviation" : 0
}

#for player
var speed : float = 0
@export var base_speed : float = 80.0

#for health component
var health : int = 0
var max_health : int = 6
@export var base_health : int = 6

#for inventory component
var weapon : EquipmentItem
var active_item : EquipmentItem
var equipment : Array[EquipmentItem]

var base_damage : int

var energy : int = 0
var ore : int = 0


func _init():
	reset()


func set_weapon_stats():
	pass


func reset():
	speed = base_speed
	max_health = base_health
	health = max_health
	equipment.clear()
	energy = 0
	ore = 0

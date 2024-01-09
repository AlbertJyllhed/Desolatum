extends Interactable

@export var required_energy : int = 10

@onready var drop_component = $DropComponent
@onready var sprite : Sprite2D = $Sprite2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var animation_player : AnimationPlayer = $AnimationPlayer

var stats : PlayerStats = preload("res://resources/Data/player_stats.tres")


func show_details():
	label.text = str(required_energy) + " energy"


func interact():
	if stats.energy < required_energy:
		return
	
	animation_player.play("activate")
	stats.energy = max(stats.energy - required_energy, 0)
	GameEvents.energy_updated.emit(stats.energy)
	sprite.z_index = -9
	collision_shape.queue_free()
	drop_component.on_died()

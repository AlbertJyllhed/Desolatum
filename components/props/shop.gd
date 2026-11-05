extends Interactable

@export var required_energy : int = 15

@onready var drop_component = $DropComponent
@onready var sprite : Sprite2D = $Sprite2D
@onready var collision_shape : CollisionShape2D = $CollisionShape2D
@onready var animation_player : AnimationPlayer = $AnimationPlayer


func _ready():
	GameEvents.navigation_updated.emit(Tiles.world_to_cell(global_position), true)


func show_details():
	label.text = str(required_energy) + " energy"


func interact():
	if Run.state.energy < required_energy:
		return
	
	animation_player.play("activate")
	Run.state.energy -= required_energy
	sprite.z_index = -9
	collision_shape.queue_free()
	drop_component.on_died()

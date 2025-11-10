extends Ability

@export var bomb_scene : PackedScene

@onready var pivot : Node2D = $Pivot

var active_charges = []
var base_layer : Node2D
var attack_vector : Vector2


func _ready() -> void:
	super._ready()
	base_layer = get_tree().get_first_node_in_group("base_layer")


func _physics_process(delta):
	super._physics_process(delta)
	attack_vector = get_global_mouse_position()
	pivot.look_at(attack_vector)
	
	if Input.is_action_just_pressed("alt_attack"):
		for charge in active_charges:
			charge.explode()
		
		active_charges.clear()


func use_ability():
	var direction = (attack_vector - global_position).normalized()
	var bomb_instance = bomb_scene.instantiate()
	base_layer.add_child(bomb_instance)
	bomb_instance.global_position = pivot.global_position
	bomb_instance.setup(direction, 100, 1, false)
	active_charges.append(bomb_instance)
	super.use_ability()

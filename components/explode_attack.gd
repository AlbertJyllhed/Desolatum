extends EnemyWeaponBase

@export var health_component : HealthComponent

var explosion_scene : PackedScene = preload("res://particles/explosion.tscn")


func _ready():
	health_component.died.connect(attack)


func attack():
	var explosion_instance = explosion_scene.instantiate()
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	base_layer.add_child(explosion_instance)
	explosion_instance.global_position = (owner as Node2D).global_position

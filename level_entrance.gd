extends StaticBody2D

@onready var front_wall : CollisionShape2D = $FrontWall
@onready var animation_player : AnimationPlayer = $AnimationPlayer

var player_scene : PackedScene = preload("res://characters/player.tscn")
var player_instance : Player


func _ready():
	animation_player.play("descend")
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	player_instance = player_scene.instantiate() as Player
	base_layer.call_deferred("add_child", player_instance)
	player_instance.global_position = global_position
	player_instance.ready.connect(player_ready)


func player_ready():
	player_instance.set_active(false)


func animation_complete():
	front_wall.set_deferred("disabled", true)
	player_instance.setup_inventory()
	player_instance.set_active(true)


func _on_area_2d_body_exited(body):
	front_wall.set_deferred("disabled", false)
	animation_player.play("ascend")

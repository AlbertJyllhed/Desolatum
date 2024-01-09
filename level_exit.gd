extends StaticBody2D

@export var unlocked_at_start : bool = false

@onready var front_wall : CollisionShape2D = $FrontWall
@onready var animation_player : AnimationPlayer = $AnimationPlayer

var transition_screen_scene : PackedScene = preload("res://ui/transition_screen.tscn")
var player : Player

var generator_scene : PackedScene = preload("res://scenes/props/generator.tscn")
var generator_position = Vector2(-24, 4)


func _ready():
	GameEvents.unlock_exit.connect(unlock)
	if unlocked_at_start:
		unlock()
		return
	
	var base_layer = get_tree().get_first_node_in_group("base_layer")
	var generator_instance = generator_scene.instantiate() as Node2D
	base_layer.call_deferred("add_child", generator_instance)
	generator_instance.global_position = global_position + generator_position


func unlock():
	front_wall.set_deferred("disabled", true)
	animation_player.play("open_doors")


func _on_exit_area_body_entered(body):
	front_wall.set_deferred("disabled", false)
	animation_player.play("close_doors")
	player = body as Player


func start_transition():
	player.set_active(false)
	animation_player.play("descend")
	
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	var transition_screen_instance = transition_screen_scene.instantiate() as TransitionScreen
	ui_layer.add_child(transition_screen_instance)
	transition_screen_instance.fade_complete.connect(on_fade_complete)
	transition_screen_instance.fade(1)


func on_fade_complete():
	SceneManager.load_next_level()

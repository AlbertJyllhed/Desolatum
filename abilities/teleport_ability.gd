extends Node2D

@export var teleporter_scene : PackedScene
@export var recharge_time : float = 20.0

@onready var pivot : Node2D = $Pivot
@onready var timer : Timer = $Timer

var active_teleporter : Node2D
var place_direction : Vector2
var charged : bool = true


func _physics_process(delta):
	place_direction = get_global_mouse_position()
	look_at(place_direction)
	
	if Input.is_action_just_pressed("alt_attack"):
		if active_teleporter:
			var player = get_tree().get_first_node_in_group("player")
			active_teleporter.teleport(player)
			active_teleporter = null
			charged = false
			timer.start(recharge_time)
			return
		
		if not charged:
			return
		
		var base_layer = get_tree().get_first_node_in_group("base_layer")
		var teleporter_instance = teleporter_scene.instantiate() as Node2D
		base_layer.add_child(teleporter_instance)
		teleporter_instance.global_position = pivot.global_position
		active_teleporter = teleporter_instance


func is_active():
	return false


func _on_timer_timeout():
	charged = true

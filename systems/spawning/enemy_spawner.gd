extends Node2D
class_name EnemySpawner

signal relocate_requested(spawner: EnemySpawner)

@export var blocked_relocate_time: float = 20.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var blocked_timer: Timer = $BlockedTimer

var lights : Array[Node2D]


func spawn_enemy(enemy_scene : PackedScene, is_aggressive : bool = false) -> bool:
	if not lights.is_empty():
		return false
	
	var enemy_instance := enemy_scene.instantiate() as Node2D
	var base_layer := get_tree().get_first_node_in_group("base_layer")
	base_layer.call_deferred("add_child", enemy_instance)
	enemy_instance.global_position = global_position
	enemy_instance.aggressive = is_aggressive
	return true


func _on_area_2d_area_entered(area):
	lights.append(area.owner)
	sprite.modulate = Color.BLACK
	if blocked_timer.is_stopped():
		blocked_timer.start(blocked_relocate_time)


func _on_area_2d_area_exited(area):
	lights.erase(area.owner)
	if not lights.is_empty():
		return
	
	blocked_timer.stop()
	sprite.modulate = Color.WHITE


func _on_blocked_timer_timeout() -> void:
	relocate_requested.emit(self)

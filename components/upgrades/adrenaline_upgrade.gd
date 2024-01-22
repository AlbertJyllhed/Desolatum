extends Upgrade

@export var time_to_reset : float = 1.0

@onready var timer : Timer = $Timer

var player : Player
var nearby_enemies : Array[Node2D]


func _ready():
	if not owner is Player:
		queue_free()
		return
	
	player = owner as Player


func _on_area_2d_body_entered(body):
	if not timer.is_stopped():
		timer.stop()
	
	nearby_enemies.append(body)
	player.max_speed = min(player.stats.base_speed * 1.5, player.stats.base_speed * 3)


func _on_area_2d_body_exited(body):
	nearby_enemies.erase(body)
	timer.start(time_to_reset)


func _on_timer_timeout():
	if nearby_enemies.size() == 0:
		player.max_speed = player.stats.base_speed

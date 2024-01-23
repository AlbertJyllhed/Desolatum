extends Upgrade

@export var time_to_reset : float = 1.0

@onready var timer : Timer = $Timer

var player : Player


func apply_upgrade(upgrade_node : Node2D):
	player = upgrade_node as Player
	player.flash_light.proximity_sensor.body_entered.connect(on_body_entered)


func on_body_entered(body):
	if not timer.is_stopped():
		timer.stop()
	
	player.max_speed = min(player.stats.base_speed * 1.4, player.stats.base_speed * 3)
	timer.start(time_to_reset)


func _on_timer_timeout():
	player.max_speed = player.stats.base_speed

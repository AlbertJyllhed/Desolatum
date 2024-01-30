extends Upgrade

@export var time_to_reset : float = 2.0

@onready var timer : Timer = $Timer

var player : Player


func apply_upgrade(upgrade_node : Node2D):
	player = upgrade_node as Player
	player.health_component.health_changed.connect(on_health_changed)


func on_health_changed(_current_health : int):
	if not timer.is_stopped():
		timer.start(time_to_reset)
		return
	
	player.stats.add_modifiers({ "damage" : 2 }, "+")
	player.stats.add_modifiers({ "bullet_spread" : 3 }, "*")
	timer.start(time_to_reset)


func _on_timer_timeout():
	player.stats.add_modifiers({ "damage" : -2 }, "+")
	player.stats.add_modifiers({ "bullet_spread" : -3 }, "*")


func remove_upgrade():
	if not timer.is_stopped():
		timer.stop()
		player.stats.add_modifiers({ "damage" : -2 }, "+")
		player.stats.add_modifiers({ "bullet_spread" : -3 }, "*")
	
	super.remove_upgrade()

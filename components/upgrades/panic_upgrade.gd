extends Upgrade

@export var time_to_reset : float = 2.0

@onready var timer : Timer = $Timer

var player : Player


func apply_upgrade(upgrade_node : Node2D):
	player = upgrade_node as Player
	player.health_component.damaged.connect(on_damaged)


func on_damaged(_amount : float) -> void:
	if not timer.is_stopped():
		timer.start(time_to_reset)
		return
	
	Run.state.add_modifiers({ "damage" : 2 }, "+")
	Run.state.add_modifiers({ "bullet_spread" : 3 }, "*")
	timer.start(time_to_reset)


func _on_timer_timeout():
	Run.state.add_modifiers({ "damage" : -2 }, "+")
	Run.state.add_modifiers({ "bullet_spread" : -3 }, "*")


func remove_upgrade():
	if not timer.is_stopped():
		timer.stop()
		Run.state.add_modifiers({ "damage" : -2 }, "+")
		Run.state.add_modifiers({ "bullet_spread" : -3 }, "*")
	
	super.remove_upgrade()

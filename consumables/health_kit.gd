extends Consumable

@export var heal_time : float = 6.0

@onready var use_timer : Timer = $UseTimer


func use_consumable():
	use_timer.start(heal_time)


func _on_use_timer_timeout():
	print("used health kit")
	super.use_consumable()

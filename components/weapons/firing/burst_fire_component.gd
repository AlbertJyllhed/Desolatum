extends FiringComponent

@export var max_bursts : int
@export_range(0, 0.2) var burst_interval : float = 0.1

@onready var burst_timer : Timer = $BurstTimer

var bursts : int


func _ready():
	super._ready()
	bursts = max_bursts


func process_trigger(just_pressed: bool, _held: bool) -> void:
	if just_pressed and ready_to_shoot:
		fire()
		burst_timer.start(burst_interval)


func _on_burst_timer_timeout():
	bursts = max(bursts - 1, 0)
	if bursts == 0:
		bursts = max_bursts
		return
	
	fire()
	burst_timer.start(burst_interval)

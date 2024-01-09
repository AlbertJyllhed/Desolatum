extends FiringComponent

@export var max_bursts : int
@export_range(0, 0.2) var burst_interval : float = 0.1

@onready var burst_timer : Timer = $BurstTimer

var bursts : int


func _ready():
	bursts = max_bursts


func _physics_process(_delta):
	if Input.is_action_just_pressed("attack"):
		if not ready_to_shoot:
			return
		
		fire()
		burst_timer.start(burst_interval)


func _on_burst_timer_timeout():
	bursts = max(bursts - 1, 0)
	if bursts == 0:
		bursts = max_bursts
		return
	
	fire()
	burst_timer.start(burst_interval)

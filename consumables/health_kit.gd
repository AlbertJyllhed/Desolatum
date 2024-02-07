extends Consumable

@export var heal_amount : float = 4.0
@export var heal_time : float = 6.0

@onready var use_timer : Timer = $UseTimer


func _ready():
	use_timer.timeout.connect(use_consumable)


func _physics_process(delta):
	if Input.is_action_just_pressed("use_consumable"):
		use_timer.start(heal_time)
	
	if Input.is_action_just_released("use_consumable"):
		use_timer.stop()


func use_consumable():
	player.health_component.heal(heal_amount)
	super.use_consumable()

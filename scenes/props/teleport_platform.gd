extends Node2D

@export var unlock_on_ready : bool = false

@onready var orb : Sprite2D = $Orb
@onready var timer : Timer = $Timer
@onready var collision_shape : CollisionShape2D = $Area2D/CollisionShape2D

var player : Player


func _ready():
	GameEvents.unlock_exit.connect(on_open_teleporter)
	timer.timeout.connect(change_level)
	if not unlock_on_ready:
		return
	
	on_open_teleporter()


func _physics_process(_delta):
	if not player:
		return
	
	player.velocity = (global_position - player.global_position).normalized() * 200


func on_open_teleporter():
	collision_shape.set_deferred("disabled", false)
	orb.show()


func change_level():
	SceneManager.load_next_level()


func _on_area_2d_body_entered(body):
	player = body as Player
	timer.start()

extends Node2D

@export var unlock_on_ready : bool = false

@onready var orb : Sprite2D = $Orb
@onready var collision_shape : CollisionShape2D = $Area2D/CollisionShape2D

var player : Player


func _ready():
	GameEvents.unlock_exit.connect(on_open_teleporter)
	if unlock_on_ready:
		on_open_teleporter()


func _physics_process(_delta):
	if not player:
		return
	
	player.velocity = (global_position - player.global_position).normalized() * 200


func on_open_teleporter():
	collision_shape.set_deferred("disabled", false)
	orb.show()


func _on_area_2d_body_entered(body):
	# Only trigger once: re-entering during the fade would start another new run.
	if not body is Player or player != null:
		return
	player = body as Player
	# The hub teleporter starts a fresh run and drops straight into its first level.
	if unlock_on_ready:
		SceneManager.start_new_run()
		return
	if Run.state.get_available_nodes().is_empty():
		GameEvents.run_won.emit()
		return
	GameEvents.show_path_select.emit()

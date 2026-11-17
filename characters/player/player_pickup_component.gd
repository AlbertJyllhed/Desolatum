@icon("res://addons/at-icons/node2d/hand.svg")
extends Node2D

@onready var attract_area : Area2D = $AttractArea

@export_group("Collect Sound")
## Played for every auto pickup collected (ore, energy).
@export var collect_sound : AudioStream = preload("res://sounds/retro_beep_03.ogg")
@export var collect_volume_db : float = -6.0
## Pickups collected within this many seconds of each other raise the pitch.
@export var chain_window : float = 0.5
## Pitch goes up one semitone per chained pickup, up to this many.
@export var max_chain_steps : int = 12

var focused_interactables : Array[Interactable]

var _collect_player : AudioStreamPlayer
var _chain : int = 0
var _last_collect_msec : int = -100000


func _ready() -> void:
	_collect_player = AudioStreamPlayer.new()
	_collect_player.max_polyphony = 4
	add_child(_collect_player)


## Plays the collect sound; quick pickups in a row climb in pitch, and the
## chain resets after a short pause.
func play_collect_sound() -> void:
	if not collect_sound:
		return
	var now := Time.get_ticks_msec()
	if now - _last_collect_msec <= int(chain_window * 1000.0):
		_chain = mini(_chain + 1, max_chain_steps)
	else:
		_chain = 0
	_last_collect_msec = now

	_collect_player.stream = collect_sound
	_collect_player.volume_db = collect_volume_db
	_collect_player.pitch_scale = pow(1.0594631, _chain)
	_collect_player.play()


func _physics_process(_delta):
	if Input.is_action_just_pressed("pick_up"):
		if focused_interactables.size() > 0:
			var closest_interactable = focused_interactables[0]
			for pickup in focused_interactables:
				if global_position.distance_to(pickup.global_position) < global_position.distance_to(closest_interactable.global_position):
					closest_interactable = pickup
			
			closest_interactable.interact()
	
	if not attract_area.has_overlapping_bodies():
		return
	
	var bodies = attract_area.get_overlapping_bodies()
	for body in bodies:
		if body is AutoPickup:
			var direction = (global_position - body.global_position).normalized()
			body.accelerate_in_direction(direction, 120)


func _on_pickup_area_body_entered(body):
	if body is AutoPickup:
		var pickup = body as AutoPickup
		if pickup.pick_up(self):
			play_collect_sound()
	
	if body is Interactable:
		focused_interactables.append(body)
		body.show_details()


func _on_pickup_area_body_exited(body):
	if body is Interactable:
		body.hide_details()
		focused_interactables.erase(body)

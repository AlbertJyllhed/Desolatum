extends Node
class_name AmmoComponent

signal has_ammo

@export var max_ammo : int = 10
@export_range(0.1, 3.0) var reload_time : float = 0.2

@onready var no_ammo_sound : AudioStreamPlayer2D = $NoAmmoSound
@onready var reload_timer = $ReloadTimer

var ammo : int = 0


func _ready():
	ammo = max_ammo
	GameEvents.ammo_updated.emit(ammo, max_ammo)
	#GameEvents.item_picked_up.connect(on_item_picked_up)


func _physics_process(delta):
	if Input.is_action_just_pressed("reload"):
		reload()


func decrement():
	ammo = max(ammo - 1, 0)
	#reload_timer.start(reload_time)
	GameEvents.ammo_updated.emit(ammo, max_ammo)


func use_ammo():
	if ammo > 0:
		reload_timer.stop()
	else:
		reload()
		return
	
	decrement()
	has_ammo.emit()


#func on_item_picked_up(item : Item):
	#if item.id != "energy":
		#return
	#
	#ammo = min(ammo + item.amount, max_ammo)
	#GameEvents.ammo_updated.emit(ammo, max_ammo)


func reload():
	no_ammo_sound.play()
	reload_timer.start(reload_time)


func _on_reload_timer_timeout():
	#ammo = min(ammo + 1, max_ammo)
	#if ammo < max_ammo:
		#reload_timer.start(reload_time)
	
	ammo = max_ammo
	GameEvents.ammo_updated.emit(ammo, max_ammo)

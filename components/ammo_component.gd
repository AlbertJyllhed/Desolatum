extends Node
class_name AmmoComponent

signal has_ammo

@export var max_ammo : int = 10
@export_range(0.1, 10.0) var reload_time : float = 0.2

@onready var no_ammo_sound : AudioStreamPlayer2D = $NoAmmoSound
@onready var reload_timer = $ReloadTimer

var ammo : int = 0
var disabled : bool = false


func _ready():
	ammo = max_ammo
	GameEvents.ammo_updated.emit(ammo, max_ammo)
	#GameEvents.item_picked_up.connect(on_item_picked_up)


func disable(value : bool):
	disabled = value
	if disabled:
		reload_timer.stop()
		return
	
	GameEvents.ammo_updated.emit(ammo, max_ammo)


func _physics_process(delta):
	if Input.is_action_just_pressed("reload") and not disabled:
		reload()


func decrement():
	ammo = max(ammo - 1, 0)
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
	ammo = max_ammo
	GameEvents.ammo_updated.emit(ammo, max_ammo)

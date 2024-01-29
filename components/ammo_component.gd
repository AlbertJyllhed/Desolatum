extends Node
class_name AmmoComponent

signal has_ammo
signal reloading(time)
signal cancel_reload

@export var max_ammo : int = 10
@export_range(0.1, 10.0) var reload_time : float = 0.2

@onready var no_ammo_sound : AudioStreamPlayer2D = $NoAmmoSound
@onready var reload_timer = $ReloadTimer

var ammo : int = 0
var disabled : bool = false


func _ready():
	ammo = max_ammo
	GameEvents.ammo_updated.emit(ammo, max_ammo)
	GameEvents.stats_changed.connect(on_stats_changed)
	#GameEvents.item_picked_up.connect(on_item_picked_up)


func disable(value : bool):
	disabled = value
	if disabled:
		if reload_timer:
			reload_timer.stop()
		
		cancel_reload.emit()
		return
	
	GameEvents.ammo_updated.emit(ammo, max_ammo)


func _physics_process(_delta):
	if Input.is_action_just_pressed("reload") and not disabled:
		reload()


func use_ammo():
	if ammo > 0:
		reload_timer.stop()
		cancel_reload.emit()
	else:
		reload()
		return
	
	ammo = max(ammo - 1, 0)
	GameEvents.ammo_updated.emit(ammo, max_ammo)
	has_ammo.emit()


#func on_item_picked_up(item : Item):
	#if item.id != "energy":
		#return
	#
	#ammo = min(ammo + item.amount, max_ammo)
	#GameEvents.ammo_updated.emit(ammo, max_ammo)


func on_stats_changed(dict : Dictionary):
	max_ammo *= dict["ammo"]["mod"]
	ammo = max_ammo
	reload_time *= dict["reload_speed"]["mod"]


func reload():
	if ammo == max_ammo:
		return
	
	if not reload_timer.is_stopped():
		return
	
	no_ammo_sound.play()
	reload_timer.start(reload_time)
	reloading.emit(reload_time)


func _on_reload_timer_timeout():
	ammo = max_ammo
	GameEvents.ammo_updated.emit(ammo, max_ammo)

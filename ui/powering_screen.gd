extends NinePatchRect

signal fully_powered

@onready var progress_bar : TextureProgressBar = $CenterContainer/VBoxContainer/TextureProgressBar
@onready var timer : Timer = $Timer

var stats : PlayerStats = preload("res://resources/Data/player_stats.tres")
var base_tick_time : float = 0.1
var tick_time : float = 0
var power : int = 0


func _ready():
	tick_time = base_tick_time


func _on_button_button_down():
	timer.start(tick_time)


func _on_button_button_up():
	timer.stop()
	tick_time = base_tick_time


func _on_timer_timeout():
	if stats.energy == 0:
		return
		
	stats.energy = max(stats.energy - 1, 0)
	GameEvents.energy_updated.emit(stats.energy)
	power += 1
	progress_bar.value = min(power, progress_bar.max_value)
	if progress_bar.value == progress_bar.max_value:
		timer.stop()
		fully_powered.emit()
		return
	
	if tick_time > 0.01:
		tick_time *= 0.9
	
	timer.start(tick_time)

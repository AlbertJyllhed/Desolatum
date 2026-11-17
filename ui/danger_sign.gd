extends Control

## Shows how dangerous it is right now: OK during calm, a flashing warning just
## before a wave, and danger while the wave is on.

## The sign pictures, in the order set on the node: warning, danger, OK.
enum Sign { WARNING, DANGER, OK }

@export var signs : Array[Texture2D]
## Seconds per half of a flash (fade down, then back up) during the warning.
@export var flash_time : float = 0.25

@onready var texture_rect : TextureRect = $TextureRect

var _flash : Tween


func _ready():
	GameEvents.wave_updated.connect(on_wave_updated)
	GameEvents.chaos_warning.connect(on_chaos_warning)


func on_wave_updated(phase : int) -> void:
	_stop_flash()
	_show(Sign.DANGER if phase == EnemyManager.Phase.CHAOS else Sign.OK)


func on_chaos_warning(_duration : float) -> void:
	_show(Sign.WARNING)
	_stop_flash()
	_flash = create_tween().set_loops()
	_flash.tween_property(texture_rect, "modulate:a", 0.2, flash_time)
	_flash.tween_property(texture_rect, "modulate:a", 1.0, flash_time)


func _show(which : Sign) -> void:
	texture_rect.texture = signs[which]


func _stop_flash() -> void:
	if _flash:
		_flash.kill()
	texture_rect.modulate.a = 1.0

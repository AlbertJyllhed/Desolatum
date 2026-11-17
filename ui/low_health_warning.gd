extends ColorRect

## Low health warning: when the player's health drops to `threshold` of max
## health or below, a red vignette fades in at the screen edges and pulses
## like a heartbeat, with an optional heartbeat sound on every beat.
##
## Put this on a full-screen ColorRect whose material is a ShaderMaterial with
## res://resources/shaders/low_health_vignette.gdshader. It's added to the HUD
## through GUI's level_hud_scenes, so it only exists in levels and hides with
## the rest of the HUD when a menu opens.

## Health fraction (of max health) at or below which the warning is on.
@export_range(0.0, 1.0, 0.01) var threshold : float = 0.34
## Sound played on every beat. Leave empty for no sound.
@export var heartbeat_sound : AudioStream
@export_range(-40.0, 12.0, 0.5) var heartbeat_volume_db : float = 0.0

@export_group("Pulse")
## Seconds between beats.
@export var beat_interval : float = 0.9
## Vignette intensity between beats (0 to 1).
@export_range(0.0, 1.0, 0.01) var rest_intensity : float = 0.45
## Vignette intensity at the peak of a beat (0 to 1).
@export_range(0.0, 1.0, 0.01) var beat_intensity : float = 1.0
## Seconds the vignette takes to fall back to rest after a beat.
@export var beat_fade_time : float = 0.5
## Seconds to fade the whole warning in or out when crossing the threshold.
@export var toggle_fade_time : float = 0.4

var _active : bool = false
## 0..1, fades the whole effect in and out when crossing the threshold.
var _strength : float = 0.0
## 0..1, jumps to 1 on each beat and decays back to 0.
var _pulse : float = 0.0
var _beat_timer : float = 0.0
var _audio_player : AudioStreamPlayer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_audio_player = AudioStreamPlayer.new()
	_audio_player.stream = heartbeat_sound
	_audio_player.volume_db = heartbeat_volume_db
	add_child(_audio_player)
	_apply_intensity()
	GameEvents.health_updated.connect(_on_health_updated)
	GameEvents.player_died.connect(_on_player_died)


func _process(delta : float) -> void:
	var target : float = 1.0 if _active else 0.0
	if toggle_fade_time > 0.0:
		_strength = move_toward(_strength, target, delta / toggle_fade_time)
	else:
		_strength = target

	if beat_fade_time > 0.0:
		_pulse = move_toward(_pulse, 0.0, delta / beat_fade_time)
	else:
		_pulse = 0.0

	if _active:
		_beat_timer -= delta
		if _beat_timer <= 0.0:
			_beat_timer += beat_interval
			_beat()

	_apply_intensity()


func _beat() -> void:
	_pulse = 1.0
	# No sound while the HUD is hidden (a menu is open).
	if _audio_player.stream and is_visible_in_tree():
		_audio_player.play()


func _apply_intensity() -> void:
	var shader_material := material as ShaderMaterial
	if shader_material == null:
		return
	var level : float = lerpf(rest_intensity, beat_intensity, _pulse)
	shader_material.set_shader_parameter("intensity", level * _strength)


func _on_health_updated(health : float, max_health : float) -> void:
	var low : bool = health > 0.0 and max_health > 0.0 and health / max_health <= threshold
	if low and not _active:
		# Beat right away so the warning is noticed on the hit that caused it.
		_beat_timer = 0.0
	_active = low


func _on_player_died() -> void:
	_active = false
	_audio_player.stop()

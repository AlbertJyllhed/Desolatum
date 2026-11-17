extends Node

## Plays the game's music. It's an autoload so a song keeps playing across scene
## changes (cave to cave) instead of restarting each time.
##
## Scenes ask for music with play(): biome levels do it from their BiomeData,
## other scenes with a MusicCue node. A scene that asks for nothing leaves the
## current music playing.
##
## A song can have two layers, calm and combat. Both play in sync from the same
## start, and enemy waves crossfade between them, so the switch always lands on
## the same spot in the music. The two files must be the same length.
##
## While the game is paused the music gets quieter, muffled and a little crunchy.
## When the player dies the same happens harder and the music sags in pitch like
## a tape running out, until the next scene loads.

const BUS_NAME := "Music"
const FADE_TIME := 1.5 ## seconds, for both the calm/combat crossfade and fading a new song in
const SILENT_DB := -80.0

# Pause and death effect
const PAUSE_MUFFLE := 0.6 ## how strong the effect is while paused (1 = full)
const DEATH_MUFFLE := 1.0
const PAUSE_FADE_TIME := 0.4 ## seconds to muffle on pause and clear on resume
const DEATH_FADE_TIME := 2.5
const MUFFLE_VOLUME_DB := -14.0 ## volume change at full muffle
const MUFFLE_CUTOFF_HZ := 600.0 ## low-pass cutoff at full muffle
const OPEN_CUTOFF_HZ := 20000.0
const MUFFLE_DRIVE := 0.5 ## lo-fi distortion drive at full muffle
const DEATH_PITCH := 0.8 ## pitch and speed the music sags to on death
const WARNING_MIX := 0.2 ## how far the combat layer creeps in during the warning before a wave

var _calm: AudioStreamPlayer
var _combat: AudioStreamPlayer
var _mix_tween: Tween
var _fade_tween: Tween
var _muffle_tween: Tween
var _pitch_tween: Tween
var _mix: float = 0.0 ## 0 = calm only, 1 = combat only
var _level: float = 1.0 ## overall fade, used when a new song starts
var _muffle: float = 0.0 ## 0 = clean, 1 = full pause/death effect
var _paused: bool = false
var _dead: bool = false
var _bus_index: int = -1
var _lowpass := AudioEffectLowPassFilter.new()
var _distortion := AudioEffectDistortion.new()


func _ready() -> void:
	# Keep the music (and its fades) going while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus()
	_add_muffle_effects()
	_calm = _make_player("Calm")
	_combat = _make_player("Combat")
	GameEvents.wave_updated.connect(_on_wave_updated)
	GameEvents.chaos_warning.connect(_on_chaos_warning)
	GameEvents.player_died.connect(_on_player_died)
	SceneManager.changing_level.connect(_on_changing_level)


## Watches the pause state instead of hooking each pause screen, so the pause
## menu, the map and anything added later all muffle the music.
func _process(_delta: float) -> void:
	var paused: bool = get_tree().paused
	if paused != _paused:
		_paused = paused
		_update_muffle()


## Starts [param calm] (and the optional [param combat] layer) on loop. Asking
## for the song that's already playing does nothing, so it carries on.
func play(calm: AudioStream, combat: AudioStream = null) -> void:
	if calm == null:
		return
	if _calm.playing and _calm.stream == calm and _combat.stream == combat:
		return

	_set_looping(calm)
	_set_looping(combat)
	_calm.stream = calm
	_combat.stream = combat

	if _mix_tween:
		_mix_tween.kill()
	_set_mix(0.0) # every song starts on its calm layer
	_calm.play()
	if combat:
		_combat.play() # same frame as calm, so the layers stay in sync
	else:
		_combat.stop()

	# Fade the new song in.
	if _fade_tween:
		_fade_tween.kill()
	_set_level(0.0)
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_level, 0.0, 1.0, FADE_TIME)


## Crossfades to the combat layer ([param on] true) or back to calm.
## Does nothing if the current song has no combat layer.
func set_combat(on: bool) -> void:
	if _combat.stream == null:
		return
	var target: float = 1.0 if on else 0.0
	if is_equal_approx(_mix, target) and not (_mix_tween and _mix_tween.is_running()):
		return
	if _mix_tween:
		_mix_tween.kill()
	_mix_tween = create_tween()
	_mix_tween.tween_method(_set_mix, _mix, target, FADE_TIME)


func _on_wave_updated(phase: int) -> void:
	set_combat(phase == EnemyManager.Phase.CHAOS)


## The combat layer creeps in quietly under the calm music before a wave; the
## normal crossfade takes it the rest of the way when the wave starts.
func _on_chaos_warning(duration: float) -> void:
	if _combat.stream == null:
		return
	if _mix_tween:
		_mix_tween.kill()
	_mix_tween = create_tween()
	_mix_tween.tween_method(_set_mix, _mix, WARNING_MIX, duration)


func _on_player_died() -> void:
	_dead = true
	_update_muffle()
	if _pitch_tween:
		_pitch_tween.kill()
	_pitch_tween = create_tween()
	_pitch_tween.tween_method(_set_pitch, _calm.pitch_scale, DEATH_PITCH, DEATH_FADE_TIME)


## The screen is black by now, so the death effect can snap back for the next scene.
func _on_changing_level() -> void:
	if not _dead:
		return
	_dead = false
	if _pitch_tween:
		_pitch_tween.kill()
	_set_pitch(1.0)
	_update_muffle()


## Fades the pause/death effect toward whatever the current state calls for.
func _update_muffle() -> void:
	var target: float = DEATH_MUFFLE if _dead else (PAUSE_MUFFLE if _paused else 0.0)
	var time: float = DEATH_FADE_TIME if _dead else PAUSE_FADE_TIME
	if _muffle_tween:
		_muffle_tween.kill()
	_muffle_tween = create_tween()
	_muffle_tween.tween_method(_set_muffle, _muffle, target, time)


func _set_muffle(value: float) -> void:
	_muffle = value
	# Exponential sweep, so the cutoff moves evenly to the ear.
	_lowpass.cutoff_hz = OPEN_CUTOFF_HZ * pow(MUFFLE_CUTOFF_HZ / OPEN_CUTOFF_HZ, value)
	_distortion.drive = MUFFLE_DRIVE * value
	# Off entirely when clean, so the music isn't touched during normal play.
	var active: bool = value > 0.001
	for effect: AudioEffect in [_lowpass, _distortion]:
		var index: int = _effect_index(effect)
		if index != -1:
			AudioServer.set_bus_effect_enabled(_bus_index, index, active)
	_apply_volumes()


func _set_pitch(value: float) -> void:
	# Both layers together, so they stay in sync.
	_calm.pitch_scale = value
	_combat.pitch_scale = value


func _set_mix(value: float) -> void:
	_mix = value
	_apply_volumes()


func _set_level(value: float) -> void:
	_level = value
	_apply_volumes()


func _apply_volumes() -> void:
	# Equal-power crossfade: the overall loudness doesn't dip halfway through.
	var gain: float = _level * db_to_linear(MUFFLE_VOLUME_DB * _muffle)
	var calm_gain: float = cos(_mix * PI / 2.0) * gain
	var combat_gain: float = sin(_mix * PI / 2.0) * gain
	_calm.volume_db = maxf(linear_to_db(calm_gain), SILENT_DB)
	_combat.volume_db = maxf(linear_to_db(combat_gain), SILENT_DB)


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = BUS_NAME
	add_child(player)
	return player


## Adds a "Music" bus (sending to Master) if the project's bus layout doesn't
## have one, so music volume can be set apart from sound effects.
func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS_NAME) != -1:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS_NAME)
	AudioServer.set_bus_send(index, "Master")


## Adds the pause/death effects to the end of the Music bus, switched off.
func _add_muffle_effects() -> void:
	_bus_index = AudioServer.get_bus_index(BUS_NAME)
	_lowpass.cutoff_hz = OPEN_CUTOFF_HZ
	_distortion.mode = AudioEffectDistortion.MODE_LOFI
	_distortion.drive = 0.0
	for effect: AudioEffect in [_lowpass, _distortion]:
		AudioServer.add_bus_effect(_bus_index, effect)
		AudioServer.set_bus_effect_enabled(_bus_index, AudioServer.get_bus_effect_count(_bus_index) - 1, false)


func _effect_index(effect: AudioEffect) -> int:
	for i: int in AudioServer.get_bus_effect_count(_bus_index):
		if AudioServer.get_bus_effect(_bus_index, i) == effect:
			return i
	return -1


## Songs are made to loop, so turn looping on here rather than relying on each
## file's import settings.
func _set_looping(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = int(wav.get_length() * wav.mix_rate)

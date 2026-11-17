class_name HitStop

## Briefly freezes the game (Engine.time_scale = 0) to make an impact feel
## heavy. Call HitStop.trigger(seconds). Overlapping calls don't add up: the
## stop simply lasts until the latest end time. Sound keeps playing.

## Bumped whenever a stop is started or extended; only the newest timer resumes.
static var _stop_id : int = 0
static var _end_msec : int = 0


static func trigger(duration : float) -> void:
	if duration <= 0.0:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.paused:
		return

	var end_msec : int = Time.get_ticks_msec() + int(duration * 1000.0)
	if end_msec <= _end_msec:
		return # a longer stop is already running

	_end_msec = end_msec
	_stop_id += 1
	var id : int = _stop_id
	Engine.time_scale = 0.0
	# Runs while paused and ignores time_scale, so it always ends the stop.
	tree.create_timer(duration, true, false, true).timeout.connect(func() -> void: _resume(id))


static func _resume(id : int) -> void:
	if id != _stop_id:
		return # a later trigger extended the stop; its timer resumes instead
	Engine.time_scale = 1.0
	_end_msec = 0

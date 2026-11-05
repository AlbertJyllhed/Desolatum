extends Node

const SAVE_PATH := "user://save.json"
const TEMP_PATH := "user://save.json.tmp"
const SAVE_VERSION := 1


func save_game() -> void:
	# Write to a temp file first so a crash mid-write can't corrupt the only save.
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return

	file.store_string(JSON.stringify({
		"version": SAVE_VERSION,
		"stats": Run.state.to_dict(),
	}, "\t"))
	file.close()

	var dir := DirAccess.open("user://")
	var err := dir.rename(TEMP_PATH.get_file(), SAVE_PATH.get_file())
	if err != OK:
		push_error("Save failed: could not replace save file (%s)" % error_string(err))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		push_warning("Save file is corrupt, starting a new run")
		return false

	var version := int(data.get("version", 0))
	if version != SAVE_VERSION:
		# Bump SAVE_VERSION when the format changes, and migrate old data here
		# if it's worth keeping. Until then, old saves are discarded.
		push_warning("Save version %d doesn't match %d, starting a new run" % [version, SAVE_VERSION])
		return false

	var stats = data.get("stats")
	if not stats is Dictionary:
		push_warning("Save file has no run data, starting a new run")
		return false

	Run.load_run(stats)
	return true


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

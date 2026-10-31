extends Node

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1


func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Save failed: %s" % error_string(FileAccess.get_open_error()))
		return
	
	file.store_string(JSON.stringify({
		"version": SAVE_VERSION,
		"level_index": SceneManager.level_index,
		"stats": Run.state.to_dict(),
	}, "\t"))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		push_warning("Save file is corrupt")
		return false
	
	Run.load_run(data.get("stats", {}))
	return true

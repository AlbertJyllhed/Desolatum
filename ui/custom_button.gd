extends Button

@export var focus_button : bool = false


func _ready():
	visibility_changed.connect(on_visibility_changed)


func on_visibility_changed():
	if not focus_button:
		return
	
	if is_visible_in_tree():
		grab_focus()

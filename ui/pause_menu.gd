extends Menu

## The pause panel is this menu's content (set Content to the Pause node);
## options and quit confirmation open in its place as sub-menus.
@onready var return_button: Button = $SubViewportContainer/SubViewport/PauseContent/ReturnButton
@onready var upgrades_button: Button = $SubViewportContainer/SubViewport/PauseContent/UpgradesButton
@onready var upgrades_menu: Menu = $SubViewportContainer/SubViewport/UpgradesMenu
@onready var options_menu: Menu = $SubViewportContainer/SubViewport/OptionsMenu
@onready var quit_confirmation: Menu = $SubViewportContainer/SubViewport/QuitConfirmation
## Shows the run (and level) seed so it can be noted down for bug reports
@onready var seed_label: Label = $SubViewportContainer/SubViewport/SeedLabel

var paused: bool = false


func _ready():
	super._ready()
	# No point offering "Return to ship" while already on the ship.
	var gui : GUI = GUI.find_for(self)
	if gui and gui.is_on_ship():
		upgrades_button.hide()
		return_button.hide()


## Esc goes back from a sub-menu first; on the pause panel it unpauses.
func _input(event):
	if not event.is_action_pressed("esc"):
		return
	if not (paused and back()):
		pause()
	get_viewport().set_input_as_handled()


func pause():
	paused = !paused
	visible = paused
	get_tree().paused = paused
	
	# Always open on the main pause panel, even if a sub-menu was left open.
	close_sub_menu()
	if paused:
		update_seed_label()


func update_seed_label() -> void:
	if not seed_label or not Run.state:
		return

	var lines : PackedStringArray = ["Run seed: %d" % Run.state.run_seed]
	var gui : GUI = GUI.find_for(self)
	var level : Level = gui.get_level() if gui else null
	if level and level.level_generator:
		lines.append("Level seed: %d" % level.level_generator.current_seed)
	if level and level.biome:
		lines.append("Biome: %s (%s)" % [level.biome.name, level.biome.resource_path.get_file()])
	seed_label.text = "\n".join(lines)


func _on_resume_button_pressed() -> void:
	pause()


func _on_upgrades_button_pressed() -> void:
	open_sub_menu(upgrades_menu)


func _on_return_button_pressed() -> void:
	pause()
	SceneManager.travel_to_ship()


func _on_settings_button_pressed() -> void:
	open_sub_menu(options_menu)


func _on_quit_button_pressed() -> void:
	open_sub_menu(quit_confirmation)

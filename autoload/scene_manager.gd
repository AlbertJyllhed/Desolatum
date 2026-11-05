extends Node

signal changing_level

@export var rest_scene: PackedScene
@export var shop_scene: PackedScene

var ship_scene: PackedScene = preload("uid://bhktsvbmclxqc")
## Shared by every biome; Level applies the biome when it loads. A path, not a
## preload, so this autoload doesn't pull the whole level in at startup.
const LEVEL_SCENE := "res://levels/main.tscn"
var map_screen_scene: PackedScene = preload("res://ui/map_screen.tscn")

var _travelling := false


func _ready():
	# Loading the save (or starting a new run) is owned by the Run autoload.
	# The map lives on the autoload so it survives scene changes and every
	# level (hub, cave, ice, nest...) gets it without being wired up by hand.
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	layer.add_child(map_screen_scene.instantiate())


## Every scene change goes through here or travel_to_node(), and both fade
## out first. The TransitionScreen in the new scene fades back in on its own.
func travel_to_ship() -> void:
	_change_scene(func(): return ship_scene)


## Starts a fresh run. The run always opens with a single level, so go straight
## into it; otherwise let the player pick from the map.
func start_new_run() -> void:
	if _travelling:
		return
	Run.new_run()
	var available := Run.state.get_available_nodes()
	if available.size() == 1:
		travel_to_node(available[0])
	else:
		GameEvents.show_path_select.emit()


func scene_for(node: MapNode) -> PackedScene:
	match node.type:
		MapNode.Type.REST:
			return rest_scene
		MapNode.Type.SHOP:
			return shop_scene
		_:
			if not has_scene_for(node):
				return null
			return load(_level_path(node.option.biome)) as PackedScene


## Cheap check that doesn't load the scene (the map screen calls this per node).
func has_scene_for(node: MapNode) -> bool:
	match node.type:
		MapNode.Type.REST:
			return rest_scene != null
		MapNode.Type.SHOP:
			return shop_scene != null
		_:
			return node.option != null and node.option.biome != null and ResourceLoader.exists(_level_path(node.option.biome))


## The biome's own scene if it has one, otherwise the shared level scene.
func _level_path(biome: BiomeData) -> String:
	return biome.scene_override if biome.scene_override != "" else LEVEL_SCENE


func travel_to_node(node: MapNode) -> void:
	if _travelling:
		return
	# Check before fading so a bad node can't leave the screen stuck on black.
	if not has_scene_for(node):
		push_error("No scene set up for map node type %s" % MapNode.Type.keys()[node.type])
		return

	Run.state.travel_to(node)
	Run.state.current_mission = node.option.mission if node.option else null
	Run.state.current_biome = node.option.biome if node.option else null
	SaveManager.save_game() # autosave on every node
	# The level is loaded once the screen is black, so the load hitch is hidden.
	_change_scene(func(): return scene_for(node))


## Fades out, then swaps to the scene [param get_scene] returns.
func _change_scene(get_scene: Callable) -> void:
	if _travelling:
		return
	_travelling = true
	var screen := get_tree().get_first_node_in_group("transition_screen") as TransitionScreen
	if screen:
		screen.fade_to_black(true)
		await screen.fade_complete
	else:
		push_warning("No node in the 'transition_screen' group, changing scene without fade")
	get_tree().paused = false # never carry a pause into the next scene
	changing_level.emit() # upgrades clean themselves up on this
	get_tree().change_scene_to_packed(get_scene.call())
	_travelling = false

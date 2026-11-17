class_name RunState
extends RefCounted

const STAT_LIST: Array[String] = [
	"health", "move_speed", "damage", "bullet_speed", "bullet_spread",
	"ammo", "reload_speed", "firing_speed", "crit_chance", "explode_chance",
]

var max_health: int
var health: float

var energy: int = 0:
	set(value):
		energy = maxi(value, 0)
		GameEvents.energy_updated.emit(energy)

var ore: int = 0:
	set(value):
		ore = maxi(value, 0)
		GameEvents.ore_updated.emit(ore)

var modifiers: Dictionary = {}
var upgrades: Array[UpgradeItem] = []
var equipment: Array[EquipmentItem] = []
var buildings: Array[BuildingItem] = []
var consumable: EquipmentItem

var depth: int = 0
var current_mission: MissionData
var current_biome: BiomeData # what the shared level scene dresses up as
var next_choices: Array[LevelOption] = []

## Seeds the map and every level of this run, so one number reproduces it all
var run_seed: int = 0

var map_layers: Array = []
var current_layer: int = -1
var current_index: int = -1


func _init(config: PlayerConfig) -> void:
	max_health = config.base_health
	health = max_health
	equipment = config.starter_equipment.duplicate()
	buildings = config.starter_buildings.duplicate()
	run_seed = randi()
	for stat in STAT_LIST:
		modifiers[stat] = Modifier.new()


# --- Stats ---------------------------------------------------------------

func add_modifiers(mods: Dictionary, type: String) -> void:
	for mod in mods:
		if not modifiers.has(mod):
			push_error("Unknown stat '%s'" % mod)
			continue
		modifiers[mod].add_to_value(mods[mod], type)
	GameEvents.stats_changed.emit(modifiers)


func update_stats() -> void:
	GameEvents.stats_changed.emit(modifiers)


func add_upgrades() -> void:
	for upgrade in upgrades:
		GameEvents.add_upgrade.emit(upgrade)


# --- Items ---------------------------------------------------------------

func on_item_picked_up(item: Item) -> void:
	if item is BuildingItem:
		if not buildings.has(item):
			buildings.append(item)
	elif item is UpgradeItem:
		upgrades.append(item)


func spend_ore(amount: int) -> bool:
	if ore < amount:
		return false
	ore -= amount
	return true


# --- Missions ------------------------------------------------------------

func start_map(config: PlayerConfig) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = run_seed
	map_layers = MapGenerator.generate(config, rng)
	print("Run seed: %d" % run_seed)
	current_layer = -1
	current_index = -1


func get_current_node() -> MapNode:
	if current_layer < 0:
		return null
	return map_layers[current_layer][current_index]


## What the player may pick right now.
func get_available_nodes() -> Array[MapNode]:
	var result : Array[MapNode] = []
	if current_layer < 0:
		for node in map_layers[0]:
			result.append(node)
		return result
	
	var current := get_current_node()
	if current_layer + 1 >= map_layers.size():
		return result
	for i in current.next:
		result.append(map_layers[current_layer + 1][i])
	return result


## Seed for the level at the current map node. Same run seed + node = same level.
## Returns -1 when no node is active (e.g. a level run straight from the editor).
func get_level_seed() -> int:
	if current_layer < 0:
		return -1
	return hash([run_seed, current_layer, current_index]) & 0x7FFFFFFF


func travel_to(node : MapNode) -> void:
	current_layer = node.layer
	current_index = node.index
	node.visited = true
	depth = node.layer + 1


func roll_choices(count : int = 3) -> void:
	next_choices.clear()
	var missions := Run.config.missions.filter(func(m): return m.min_depth <= depth)
	missions.shuffle() # distinct mission types per choice
	for i in mini(count, missions.size()):
		var option := LevelOption.new()
		option.mission = missions[i]
		option.biome = Run.config.biomes.pick_random()
		next_choices.append(option)


# --- Saving --------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"health": health,
		"energy": energy,
		"ore": ore,
		"upgrades": upgrades.map(func(i): return i.resource_path),
		"equipment": equipment.map(func(i): return i.resource_path),
		"buildings": buildings.map(func(i): return i.resource_path),
		"consumable": consumable.resource_path if consumable else "",
		"depth": depth,
		"choices": next_choices.map(func(o): return [o.biome.resource_path, o.mission.resource_path]),
		"map": map_layers.map(func(layer): return layer.map(func(n): return {
			"type": n.type,
			"next": n.next,
			"visited": n.visited,
			"biome": n.option.biome.resource_path if n.option and n.option.biome else "",
			"mission": n.option.mission.resource_path if n.option and n.option.mission else "",
		})),
		"run_seed": run_seed,
		"current_layer": current_layer,
		"current_index": current_index,
	}


static func from_dict(config: PlayerConfig, data: Dictionary) -> RunState:
	var state := RunState.new(config)
	state.health = data.get("health", state.max_health)
	state.energy = int(data.get("energy", 0))
	state.ore = int(data.get("ore", 0))
	
	for item in _load_all(data.get("upgrades", [])):
		state.upgrades.append(item)
	
	if data.has("equipment"):
		state.equipment.clear()
		for item in _load_all(data["equipment"]):
			state.equipment.append(item)
	
	if data.has("buildings"):
		state.buildings.clear()
		for item in _load_all(data["buildings"]):
			state.buildings.append(item)
	
	state.consumable = _load_resource(data.get("consumable", ""))
	
	state.depth = int(data.get("depth", 0))
	# saves from before seeding keep the random seed picked in _init
	state.run_seed = int(data.get("run_seed", state.run_seed))
	
	if data.has("choices"):
		state.next_choices.clear()
		for pair in data["choices"]:
			if not pair is Array or pair.size() < 2:
				continue
			var option := LevelOption.new()
			option.biome = _load_resource(pair[0])
			option.mission = _load_resource(pair[1])
			if option.biome and option.mission:
				state.next_choices.append(option)
	
	state.map_layers.clear()
	var map: Array = data.get("map", [])
	for l in map.size():
		var layer : Array[MapNode] = []
		for i in map[l].size():
			var d : Dictionary = map[l][i]
			var node := MapNode.new()
			node.layer = l
			node.index = i
			node.type = int(d.get("type", MapNode.Type.MISSION)) as MapNode.Type
			node.visited = d.get("visited", false)
			for n in d.get("next", []):
				node.next.append(int(n))   # JSON gives floats back
			var biome = _load_resource(d.get("biome", ""))
			if biome:
				node.option = LevelOption.new()
				node.option.biome = biome
				node.option.mission = _load_resource(d.get("mission", ""))
			layer.append(node)
		state.map_layers.append(layer)
	state.current_layer = int(data.get("current_layer", -1))
	state.current_index = int(data.get("current_index", -1))
	
	if not state._map_is_valid():
		push_warning("Saved map is invalid, generating a new one")
		state.start_map(config)
	
	return state


## Loads a saved resource path. Returns null (with a warning) if the
## resource was renamed or deleted since the save was written.
static func _load_resource(path) -> Resource:
	if not path is String or path == "":
		return null
	if not ResourceLoader.exists(path):
		push_warning("Save references missing resource '%s', skipping it" % path)
		return null
	return load(path)


static func _load_all(paths) -> Array[Resource]:
	var result: Array[Resource] = []
	if not paths is Array:
		return result
	for path in paths:
		var res := _load_resource(path)
		if res:
			result.append(res)
	return result


## Checks that the loaded map can actually be played: it isn't empty, every
## link points at a real node, the current position exists, and every node
## that needs a level has one. (The mission may be null, e.g. the boss while
## PlayerConfig.boss_mission isn't set yet.)
func _map_is_valid() -> bool:
	if map_layers.is_empty():
		return false
	for l in map_layers.size():
		for node: MapNode in map_layers[l]:
			if node.type != MapNode.Type.REST and node.type != MapNode.Type.SHOP:
				if node.option == null or node.option.biome == null:
					return false
			if l + 1 < map_layers.size():
				for n in node.next:
					if n < 0 or n >= map_layers[l + 1].size():
						return false
	if current_layer >= 0:
		if current_layer >= map_layers.size() or current_index < 0 or current_index >= map_layers[current_layer].size():
			return false
	return true

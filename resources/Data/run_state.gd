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


func _init(config: PlayerConfig) -> void:
	max_health = config.base_health
	health = max_health
	equipment = config.starter_equipment.duplicate()
	buildings = config.starter_buildings.duplicate()
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
	}


static func from_dict(config: PlayerConfig, data: Dictionary) -> RunState:
	var state := RunState.new(config)
	state.health = data.get("health", state.max_health)
	state.energy = data.get("energy", 0)
	state.ore = data.get("ore", 0)
	
	for path in data.get("upgrades", []):
		state.upgrades.append(load(path))
	
	if data.has("equipment"):
		state.equipment.clear()
		for path in data["equipment"]:
			state.equipment.append(load(path))
	
	if data.has("buildings"):
		state.buildings.clear()
		for path in data["buildings"]:
			state.buildings.append(load(path))
	
	var consumable_path: String = data.get("consumable", "")
	state.consumable = load(consumable_path) if consumable_path != "" else null
	return state

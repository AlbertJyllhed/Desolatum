extends Node
class_name EnemyManager

enum Phase { CALM, CHAOS }

@export var enemy_list: EnemyList
@export var calm_phase: DirectorPhase
@export var chaos_phase: DirectorPhase

@export_group("Intensity")
@export var damage_intensity: float = 0.15 ## added per health point lost
@export var intensity_decay: float = 0.05 ## lost per second
@export_range(0.0, 1.0) var peak_intensity: float = 0.8
@export_range(0.0, 1.0) var relax_intensity: float = 0.3

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer

var phase: Phase
var current: DirectorPhase
var intensity: float = 0.0
var peaked: bool = false
var last_health: float = -1.0

## Multipliers on enemy count
var modifiers: Dictionary = { "health": 1.0, "energy": 1.0 }

var spawners : Array[EnemySpawner]

const SPAWNER_SCENE := preload("uid://bsu0qwh6vyytv")
const LIGHT_MASK := 2048
const MIN_PLAYER_DISTANCE := 96.0

var light_probe := CircleShape2D.new()
var light_query := PhysicsPointQueryParameters2D.new()


func _ready():
	GameEvents.start_wave.connect(func(_index): enter_phase(Phase.CHAOS))
	GameEvents.health_updated.connect(on_health_updated)
	GameEvents.energy_updated.connect(on_energy_updated)
	spawn_timer.timeout.connect(spawn)
	wave_timer.timeout.connect(on_phase_timeout)
	
	enemy_list.setup()
	enter_phase(Phase.CALM)
	spawn_timer.start(get_spawn_time())
	
	light_query.collide_with_areas = true
	light_query.collide_with_bodies = false
	light_query.collision_mask = LIGHT_MASK


func enter_phase(new_phase: Phase):
	phase = new_phase
	current = calm_phase if phase == Phase.CALM else chaos_phase
	peaked = false
	wave_timer.start(randf_range(current.min_duration, current.max_duration))
	
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	remove_excess_enemies(enemies)
	for enemy in enemies:
		enemy.aggressive = current.aggressive
	
	GameEvents.wave_updated.emit(phase)


func on_phase_timeout():
	# Calm always ends on its timer. Chaos usually ends early
	# so this is its safety cap.
	enter_phase(Phase.CHAOS if phase == Phase.CALM else Phase.CALM)


func _process(delta: float) -> void:
	intensity = move_toward(intensity, 0.0, intensity_decay * delta)
	if phase != Phase.CHAOS:
		return
	
	# Chaos runs until the player has been pushed to a peak,
	# then relaxes once they've recovered
	if intensity >= peak_intensity:
		peaked = true
	elif peaked and intensity <= relax_intensity:
		enter_phase(Phase.CALM)


func add_intensity(amount: float):
	intensity = clampf(intensity + amount, 0.0, 1.0)


func add_spawner(spawner : EnemySpawner):
	spawners.append(spawner)
	spawner.relocate_requested.connect(relocate_spawner)


func relocate_spawner(old: EnemySpawner):
	var pos = find_dark_position()
	if pos == null:
		old.blocked_timer.start(5.0) # nothing free right now, try again soon
		return
	
	spawners.erase(old)
	old.queue_free()
	
	var new_spawner := SPAWNER_SCENE.instantiate() as EnemySpawner
	new_spawner.global_position = pos
	get_tree().get_first_node_in_group("base_layer").add_child(new_spawner)
	add_spawner(new_spawner)


func find_dark_position() -> Variant:
	var tilemap := get_tree().get_first_node_in_group("tilemap_layer") as TileMapLayer
	var grid := get_tree().get_first_node_in_group("pathfinding") as PathfindingGrid
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return null
	
	var cells := tilemap.get_used_cells_by_id(Tiles.Id.GROUND)
	cells.shuffle()
	
	light_probe.radius = 8.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = light_probe
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = LIGHT_MASK
	
	var space := get_viewport().world_2d.direct_space_state
	for cell in cells.slice(0, 40): # cap attempts
		if Building.occupied.has(cell):
			continue
		if grid.astar_grid.is_in_boundsv(cell) and grid.astar_grid.is_point_solid(cell):
			continue
		
		var pos := tilemap.to_global(tilemap.map_to_local(cell))
		if pos.distance_to(player.global_position) < MIN_PLAYER_DISTANCE:
			continue
		
		query.transform = Transform2D(0, pos)
		if space.intersect_shape(query, 1).is_empty(): # not inside any light
			return pos
	return null


func is_in_light(pos: Vector2) -> bool:
	light_query.position = pos
	var space := get_viewport().world_2d.direct_space_state
	for hit in space.intersect_point(light_query, 8):
		# The light areas are children of the Light2D, so also respect a switched-off flashlight
		var light := hit.collider.get_parent() as Light2D
		if light == null or light.enabled:
			return true
	return false


func remove_excess_enemies(enemies : Array[Node]):
	var excess := enemies.size() - get_max_enemies()
	if excess <= 0:
		return
	
	var removable := enemies.filter(
		func(e: Node2D): return not is_in_light(e.global_position))
	removable.shuffle()
	
	var removed_amount := 0
	for enemy in removable.slice(0, excess):
		enemy.queue_free()
		removed_amount += 1
	
	print("removed %s enemies" % removed_amount)


func on_health_updated(health, max_health):
	# health modifier lowers the max enemies based on player health
	if last_health >= 0.0 and health < last_health:
		add_intensity((last_health - health) * damage_intensity)
	last_health = health
	modifiers["health"] = max(float(health) / float(max_health), 0.25)


func on_energy_updated(energy):
	# energy modifier raises the max enemies based on player energy
	modifiers["energy"] = min(1.0 + float(energy) / 100.0, 1.5)


func get_modifier() -> float:
	var total := 1.0
	for value in modifiers.values():
		total *= value
	return total


func get_max_enemies() -> int:
	return ceili(current.max_enemies * get_modifier())


func get_spawn_time() -> float:
	# A stressed player gets a bit more breathing room between spawns
	return current.spawn_time * lerpf(1.0, 1.5, intensity)


func spawn():
	var total_enemies = get_tree().get_nodes_in_group("enemies").size()
	var spawn_chance = 0.3
	for spawner in spawners:
		if total_enemies >= get_max_enemies():
			break
		
		if randf() > spawn_chance:
			continue
		
		var enemy_scene = enemy_list.spawn_table.pick_item()
		if spawner.spawn_enemy(enemy_scene, current.aggressive):
			total_enemies += 1
	
	spawn_timer.start(get_spawn_time())

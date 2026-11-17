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

@export_group("Chaos warning")
## How many seconds before calm ends the warning starts (HUD, camera, sound and music build up).
@export var warning_time: float = 10.0
## Played once when the warning starts.
@export var warning_howl: AudioStream = preload("res://sounds/monster_howl.wav")
@export var warning_howl_volume_db: float = -6.0
## Builds up over the warning. Made to be warning_time long.
@export var warning_rumble: AudioStream = preload("res://sounds/chaos_rumble.ogg")
@export var warning_rumble_volume_db: float = -2.0

@export_group("Horde burst")
## Screen shake when a phase's burst starts (0 to 1).
@export var burst_shake: float = 0.6
## Played when a phase's burst starts.
@export var burst_roar: AudioStream = preload("res://sounds/monster_roar_1.wav")
@export var burst_roar_volume_db: float = -4.0

@export_group("Spawner relocation")
## Random ground cells tried when a lit spawner looks for a new dark spot.
@export var relocate_attempts: int = 40
## Seconds before a spawner tries again when no dark spot was found.
@export var relocate_retry_time: float = 5.0

@onready var spawn_timer: Timer = $SpawnTimer
@onready var wave_timer: Timer = $WaveTimer
var warning_timer := Timer.new()
var howl_player := AudioStreamPlayer.new()
var rumble_player := AudioStreamPlayer.new()
var roar_player := AudioStreamPlayer.new()
var burst_timer := Timer.new()
var burst_left: int = 0

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
const LIGHT_PROBE_RADIUS := 8.0

var light_probe := CircleShape2D.new()
var light_query := PhysicsPointQueryParameters2D.new()
var light_shape_query := PhysicsShapeQueryParameters2D.new()
## Every ground cell in the level, for picking spawner spots. Filled after the
## level is generated and kept up to date as walls are broken.
var ground_cells: Array[Vector2i] = []


func _ready():
	GameEvents.start_wave.connect(func(_index): enter_phase(Phase.CHAOS))
	GameEvents.health_updated.connect(on_health_updated)
	GameEvents.energy_updated.connect(on_energy_updated)
	GameEvents.level_generated.connect(cache_ground_cells)
	GameEvents.tile_broken.connect(on_tile_broken)
	spawn_timer.timeout.connect(spawn)
	wave_timer.timeout.connect(on_phase_timeout)

	warning_timer.one_shot = true
	warning_timer.timeout.connect(on_warning)
	add_child(warning_timer)
	howl_player.stream = warning_howl
	howl_player.volume_db = warning_howl_volume_db
	add_child(howl_player)
	rumble_player.stream = warning_rumble
	rumble_player.volume_db = warning_rumble_volume_db
	add_child(rumble_player)
	roar_player.stream = burst_roar
	roar_player.volume_db = burst_roar_volume_db
	add_child(roar_player)
	burst_timer.timeout.connect(on_burst_tick)
	add_child(burst_timer)

	enemy_list.setup()
	enter_phase(Phase.CALM)
	spawn_timer.start(get_spawn_time())
	
	light_query.collide_with_areas = true
	light_query.collide_with_bodies = false
	light_query.collision_mask = LIGHT_MASK

	light_probe.radius = LIGHT_PROBE_RADIUS
	light_shape_query.shape = light_probe
	light_shape_query.collide_with_areas = true
	light_shape_query.collide_with_bodies = false
	light_shape_query.collision_mask = LIGHT_MASK


func enter_phase(new_phase: Phase):
	phase = new_phase
	current = calm_phase if phase == Phase.CALM else chaos_phase
	peaked = false
	var duration: float = randf_range(current.min_duration, current.max_duration)
	wave_timer.start(duration)
	# Calm warns before it runs out. Chaos started some other way (the generator) comes without one.
	if phase == Phase.CALM:
		warning_timer.start(maxf(duration - warning_time, 0.05))
	else:
		warning_timer.stop()

	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	remove_excess_enemies(enemies)
	for enemy in enemies:
		enemy.aggressive = current.aggressive

	start_burst()
	GameEvents.wave_updated.emit(phase)


func on_warning():
	if phase != Phase.CALM:
		return
	GameEvents.chaos_warning.emit(minf(warning_time, wave_timer.time_left))
	if warning_howl:
		howl_player.play()
	if warning_rumble:
		rumble_player.play()


## Pours the phase's burst out of the dark over burst_duration, with a shake and a roar.
func start_burst():
	burst_timer.stop()
	var depth: int = Run.state.depth if Run.state else 1
	burst_left = current.get_burst_size(depth)
	if burst_left <= 0:
		return
	burst_timer.start(current.burst_duration / burst_left)

	var camera := get_viewport().get_camera_2d() as PlayerCamera
	if camera:
		camera.add_shake(burst_shake)
	if burst_roar:
		roar_player.play()


func on_burst_tick():
	if burst_left <= 0 or EnemyEntity.all_enemies.size() >= get_max_enemies():
		burst_left = 0
		burst_timer.stop()
		return
	burst_left -= 1

	var dark := spawners.filter(func(s: EnemySpawner): return s.lights.is_empty())
	if dark.is_empty():
		return
	var spawner := dark.pick_random() as EnemySpawner
	spawner.spawn_enemy(enemy_list.spawn_table.pick_item(), current.aggressive)


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
		old.blocked_timer.start(relocate_retry_time) # nothing free right now, try again soon
		return
	
	spawners.erase(old)
	old.queue_free()
	
	var new_spawner := SPAWNER_SCENE.instantiate() as EnemySpawner
	new_spawner.global_position = pos
	get_tree().get_first_node_in_group("base_layer").add_child(new_spawner)
	add_spawner(new_spawner)


## Remembers every ground cell once the level exists, so relocating a spawner
## doesn't have to scan the whole tilemap each time.
func cache_ground_cells():
	var tilemap := get_tree().get_first_node_in_group("tilemap_layer") as TileMapLayer
	if tilemap:
		ground_cells = tilemap.get_used_cells_by_id(Tiles.Id.GROUND)


## A broken wall or ceiling becomes floor, so it's a new spot a spawner could use.
func on_tile_broken(tile_position: Vector2i):
	if not ground_cells.is_empty():
		ground_cells.append(tile_position)


func find_dark_position() -> Variant:
	var tilemap := get_tree().get_first_node_in_group("tilemap_layer") as TileMapLayer
	var grid := get_tree().get_first_node_in_group("pathfinding") as PathfindingGrid
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not player:
		return null
	if ground_cells.is_empty():
		cache_ground_cells() # in case the level was generated before this listened
	if ground_cells.is_empty():
		return null

	var space := get_viewport().world_2d.direct_space_state
	for i in relocate_attempts:
		var cell: Vector2i = ground_cells.pick_random()
		if Building.occupied.has(cell):
			continue
		if grid.astar_grid.is_in_boundsv(cell) and grid.astar_grid.is_point_solid(cell):
			continue
		
		var pos := tilemap.to_global(tilemap.map_to_local(cell))
		if pos.distance_to(player.global_position) < MIN_PLAYER_DISTANCE:
			continue
		
		light_shape_query.transform = Transform2D(0, pos)
		if space.intersect_shape(light_shape_query, 1).is_empty(): # not inside any light
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
	
	for enemy in removable.slice(0, excess):
		enemy.queue_free()


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
	# EnemyEntity keeps this list up to date itself (added on ready, removed on death).
	var total_enemies := EnemyEntity.all_enemies.size()
	for spawner in spawners:
		if total_enemies >= get_max_enemies():
			break

		if randf() > current.spawn_chance:
			continue
		
		var enemy_scene = enemy_list.spawn_table.pick_item()
		if spawner.spawn_enemy(enemy_scene, current.aggressive):
			total_enemies += 1
	
	spawn_timer.start(get_spawn_time())

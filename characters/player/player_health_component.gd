extends HealthComponent
class_name PlayerHealthComponent

## Camera shake when the player takes damage (0 to 1).
@export var hit_shake : float = 0.4


func setup() -> void:
	max_health = Run.state.max_health
	current_health = Run.state.health
	health_changed.connect(on_health_changed)
	damaged.connect(on_damaged)
	died.connect(on_died)
	GameEvents.health_updated.emit(current_health, max_health)
	GameEvents.stats_changed.connect(on_stats_changed)


## The base class handles damage and healing; this keeps the run state and the HUD in sync.
func on_health_changed(health : float) -> void:
	Run.state.health = health
	GameEvents.health_updated.emit(health, max_health)


func on_damaged(_amount : float) -> void:
	var camera := get_viewport().get_camera_2d() as PlayerCamera
	if camera:
		camera.add_shake(hit_shake)


func on_died() -> void:
	GameEvents.player_died.emit()


func on_stats_changed(mods : Dictionary) -> void:
	var old_health := max_health
	max_health = maxi(int(mods["health"].get_values(Run.config.base_health)), 1)
	if current_health >= old_health:
		current_health = max_health

	Run.state.max_health = max_health
	Run.state.health = current_health
	GameEvents.health_updated.emit(current_health, max_health)

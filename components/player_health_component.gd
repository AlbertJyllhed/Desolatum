extends HealthComponent
class_name PlayerHealthComponent

var game_over_screen_scene : PackedScene = preload("res://ui/game_over_screen.tscn")


func setup():
	max_health = Run.state.max_health
	current_health = Run.state.health
	GameEvents.health_updated.emit(current_health, max_health)
	GameEvents.stats_changed.connect(on_stats_changed)


func damage(damage_amount : float):
	if dead or current_health <= 0:
		return
	
	current_health = max(current_health - damage_amount, 0)
	Run.state.health = current_health
	health_changed.emit(current_health)
	spawn_particles()
	GameEvents.health_updated.emit(current_health, max_health)
	Callable(check_death).call_deferred()


func heal(heal_amount : float):
	current_health = min(current_health + heal_amount, max_health)
	Run.state.health = current_health
	GameEvents.health_updated.emit(current_health, max_health)


func check_death():
	if dead or current_health > 0:
		return
	
	dead = true
	died.emit()
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	var game_over_screen_instance = game_over_screen_scene.instantiate()
	ui_layer.add_child(game_over_screen_instance)
	ui_layer.move_child(game_over_screen_instance, 0)
	owner.queue_free()


func on_stats_changed(mods : Dictionary):
	var old_health := max_health
	max_health = maxi(int(mods["health"].get_values(Run.config.base_health)), 1)
	if current_health >= old_health:
		current_health = max_health
	
	Run.state.max_health = max_health
	Run.state.health = current_health
	GameEvents.health_updated.emit(current_health, max_health)

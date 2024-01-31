extends HealthComponent
class_name PlayerHealthComponent

var stats : PlayerStats
var game_over_screen_scene : PackedScene = preload("res://ui/game_over_screen.tscn")


func setup(new_stats : PlayerStats):
	stats = new_stats
	max_health = stats.player_stats["max_health"]
	current_health = stats.player_stats["health"]
	GameEvents.health_updated.emit(current_health, max_health)
	GameEvents.stats_changed.connect(on_stats_changed)
	GameEvents.item_picked_up.connect(on_item_picked_up)


func damage(damage_amount : float):
	current_health = max(current_health - damage_amount, 0)
	stats.player_stats["health"] = current_health
	health_changed.emit(current_health)
	spawn_particles()
	GameEvents.health_updated.emit(current_health, max_health)
	Callable(check_death).call_deferred()


func check_death():
	if current_health == 0:
		died.emit()
		var ui_layer = get_tree().get_first_node_in_group("ui_layer")
		var game_over_screen_instance = game_over_screen_scene.instantiate()
		ui_layer.add_child(game_over_screen_instance)
		ui_layer.move_child(game_over_screen_instance, 0)
		owner.queue_free()


func on_item_picked_up(item : Item):
	if item.id == "health":
		current_health = min(current_health + 1, max_health)
		stats.player_stats["health"] = current_health
		GameEvents.health_updated.emit(current_health, max_health)


func on_stats_changed(mods : Dictionary):
	max_health = max(mods["health"].get_values(stats.base_health), 1)
	#max_health = max((stats.base_health + mods["health"][0]) * mods["health"][1], 1)
	GameEvents.health_updated.emit(current_health, max_health)

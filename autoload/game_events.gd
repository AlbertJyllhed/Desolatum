extends Node

@warning_ignore_start("unused_signal")

# Player events
signal item_picked_up(item)
signal ammo_updated(ammo, max_ammo)
signal health_updated(health, max_health)
signal weapons_updated(index)
signal energy_updated(energy)
signal ore_updated(ore)
signal ability_updated(recharge_time, uses)
signal building_selected(item)
signal build_mode_changed(active)
signal add_upgrade(upgrade_item)
signal stats_changed(modifiers)
signal reset_stats

# World events
signal level_generated
signal navigation_updated(tile_position, value)
signal wave_updated(index)
signal start_wave(index)
signal unlock_exit
signal show_path_select
signal run_won
signal set_camera_target(target)

# Mission events
signal mission_started(mission)
signal mission_progress(mission)
signal mission_completed(mission)
signal enemy_killed(enemy)
signal objective_done(objective)

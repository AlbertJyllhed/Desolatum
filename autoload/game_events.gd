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
signal player_died

# World events
signal level_generated
signal navigation_updated(tile_position, value)
## A wall or ceiling tile was broken (mined, blown up, or broke along with a neighbour).
signal tile_broken(tile_position)
signal wave_updated(index)
signal start_wave(index)
## Sent [param duration] seconds before calm turns to chaos, so the HUD, camera
## and audio can build up to the wave.
signal chaos_warning(duration)
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

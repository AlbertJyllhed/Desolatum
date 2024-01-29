extends Node

signal item_picked_up(item)
signal ammo_updated(ammo, max_ammo)
signal health_updated(health, max_health)
signal weapons_updated(index)
signal energy_updated(energy)
signal ore_updated(ore)
signal navigation_updated(tile_position, value)
signal upgrade_added(upgrade_item, upgrade_instance)
signal stats_changed(stats_dict)
signal wave_updated(index)
signal start_wave(index)
signal unlock_exit()

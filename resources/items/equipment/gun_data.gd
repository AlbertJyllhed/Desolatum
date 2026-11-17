@icon("res://addons/at-icons/node2d/gun.svg")
extends Resource
class_name GunData

## All the tuning for one gun. Assign it to an EquipmentItem's gun_data and
## the generic gun scene (components/weapons/player/gun.tscn) builds itself
## from these values, so no per-weapon scene is needed.

enum FireMode { SINGLE, AUTO, BURST }
## NONE = unlimited, no reloading (e.g. melee)
enum AmmoMode { MAGAZINE, RECHARGE, NONE }

@export_group("Firing")
@export var fire_mode := FireMode.SINGLE
@export_range(0, 6, 0.01) var cooldown: float = 1.0
## Burst mode only: shots per trigger pull
@export var burst_count: int = 3
## Burst mode only: time between shots in a burst
@export_range(0, 0.2, 0.01) var burst_interval: float = 0.05
## Slows how fast the gun can turn toward the aim while attack is held
@export var limit_turn_while_firing: bool = false
## Degrees per second the gun can turn while attack is held. 0 = locked
@export_range(0, 1080, 1, "or_greater") var firing_turn_speed: float = 90.0

@export_group("Movement")
## Player move speed is multiplied by this after each attack. 1 = no slowdown
@export_range(0, 1, 0.05) var attack_move_speed_multiplier: float = 1.0
## Seconds the slowdown lasts after each attack
@export_range(0, 2, 0.05, "or_greater") var attack_slow_duration: float = 0.3

@export_group("Ammo")
@export var ammo_mode := AmmoMode.MAGAZINE
@export var ammo: int = 10
@export_range(0.1, 10.0, 0.1, "or_greater") var reload_time: float = 1.0
@export var reload_while_holstered: bool = false

@export_group("Projectile")
@export var projectile: PackedScene
@export var damage: int = 1
@export var speed: float = 400.0
## Random inaccuracy per projectile, in radians either side of its aim
@export var spread: float = 0.1
@export_range(0, 1, 0.05) var crit_chance: float = 0.0
@export_range(0, 1, 0.05) var explode_chance: float = 0.0
## When off (e.g. melee) only damage and crit upgrades apply;
## bullet speed, spread and explode chance stay at the values above
@export var use_projectile_upgrades: bool = true

@export_group("Shot Pattern")
## Projectiles fired per shot
@export_range(1, 32, 1, "or_greater") var projectile_count: int = 1
## Total angle in degrees the projectiles fan out over, evenly spaced.
## 0 = all fly in the same direction
@export_range(0, 360, 1) var fan_angle: float = 0.0
## Side-by-side distance in pixels between neighbouring projectiles,
## centred on the barrel. 0 = all spawn at the muzzle
@export var projectile_spacing: float = 0.0

@export_group("Presentation")
## Leave empty to use the shared weapons sheet set in gun.tscn
@export var texture: Texture2D
@export var sprite_frame: int = 0
## Distance from the pivot to where bullets spawn
@export var muzzle_offset: float = 12.0
## Picked at random (with slight pitch variation) for each shot
@export var sounds: Array[AudioStream] = []
## Camera kick in pixels, opposite the firing direction (e.g. 1 light, 4 heavy)
@export var recoil: float = 1.0
## Extra camera shake per shot, 0 to 1 (0 for most guns, ~0.1-0.2 for heavy ones)
@export var shake_power: float = 0.0
## Casing ejected on each shot (a ShellCasing scene). Leave empty for none
@export var casing_scene: PackedScene
## Replaces the default kick-back played on each attack (e.g. a melee swing).
## Tracks should target nodes in gun.tscn, such as Pivot/WeaponSprite
@export var attack_animation: Animation

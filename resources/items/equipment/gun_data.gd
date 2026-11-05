@icon("res://addons/at-icons/node2d/gun.svg")
extends Resource
class_name GunData

## All the tuning for one gun. Assign it to an EquipmentItem's gun_data and
## the generic gun scene (components/weapons/player/gun.tscn) builds itself
## from these values, so no per-weapon scene is needed.

enum FireMode { SINGLE, AUTO, BURST }
enum AmmoMode { MAGAZINE, RECHARGE }

@export_group("Firing")
@export var fire_mode := FireMode.SINGLE
@export_range(0, 6, 0.01) var cooldown: float = 1.0
## Burst mode only: shots per trigger pull
@export var burst_count: int = 3
## Burst mode only: time between shots in a burst
@export_range(0, 0.2, 0.01) var burst_interval: float = 0.05

@export_group("Ammo")
@export var ammo_mode := AmmoMode.MAGAZINE
@export var ammo: int = 10
@export_range(0.1, 10.0, 0.1, "or_greater") var reload_time: float = 1.0
@export var reload_while_holstered: bool = false

@export_group("Projectile")
@export var projectile: PackedScene
@export var damage: int = 1
@export var speed: float = 400.0
@export var spread: float = 0.1
## One entry per projectile fired, as an angle offset in degrees
@export var pattern: Array[float] = [0.0]
@export_range(0, 1, 0.05) var crit_chance: float = 0.0
@export_range(0, 1, 0.05) var explode_chance: float = 0.0

@export_group("Presentation")
## Leave empty to use the shared weapons sheet set in gun.tscn
@export var texture: Texture2D
@export var sprite_frame: int = 0
## Distance from the pivot to where bullets spawn
@export var muzzle_offset: float = 12.0
## Picked at random (with slight pitch variation) for each shot
@export var sounds: Array[AudioStream] = []
@export var recoil: float = 0.1
@export var shake_power: float = 2.0

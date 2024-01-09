extends Control

signal upgrade_selected(upgrade : UpgradeItem)

@onready var container : HBoxContainer = $HBoxContainer

var upgrade_choice_scene : PackedScene = preload("res://ui/upgrade_ui.tscn")


func _ready():
	get_tree().paused = true


func set_upgrades(upgrades : Array[UpgradeItem]):
	for upgrade in upgrades:
		var upgrade_choice_instance = upgrade_choice_scene.instantiate()
		container.add_child(upgrade_choice_instance)
		upgrade_choice_instance.set_upgrade(upgrade)
		upgrade_choice_instance.selected.connect(on_upgrade_selected.bind(upgrade))


func on_upgrade_selected(upgrade : UpgradeItem):
	upgrade_selected.emit(upgrade)
	get_tree().paused = false
	queue_free()

extends Control
class_name UpgradeUI

@onready var icon: TextureRect = $HBoxContainer/Icon
@onready var label: Label = $HBoxContainer/Label

## The upgrade tied to this UI element
var _upgrade: UpgradeItem
## How many instances of a specific upgrade the player has
var _amount: int = 1


## Sets up the UpgradeUI with a new UpgradeItem.
## amount is how many upgrades are added (default is 1).
func setup(upgrade: UpgradeItem, amount: int = 1) -> void:
	_upgrade = upgrade
	_amount += amount
	icon.texture = upgrade.icon
	label.text = "%s +%s" % [upgrade.name, amount]


func has_upgrade(upgrade: UpgradeItem) -> bool:
	if _upgrade == upgrade:
		return true
	return false

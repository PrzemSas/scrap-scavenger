extends Node

signal coins_changed(new_amount: int)
signal inventory_changed()
signal upgrade_purchased(upgrade_id: String)

var coins: int = 0
var inventory: Array = []
var max_slots: int = 8
var click_power: int = 1
var luck_bonus: float = 0.0

# Upgrade levels
var upgrades: Dictionary = {
	"bigger_bag": 0,
	"click_power": 0,
	"lucky_find": 0,
}

# Upgrade costs: {base, multiplier, max_level, effect_desc}
var upgrade_config: Dictionary = {
	"bigger_bag": {"base": 30, "mult": 1.7, "max": 8, "desc": "+2 inventory slots"},
	"click_power": {"base": 60, "mult": 2.0, "max": 5, "desc": "+1 scrap per click"},
	"lucky_find": {"base": 100, "mult": 2.2, "max": 6, "desc": "+3% rare chance"},
}

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false

func add_to_inventory(item_data: Dictionary) -> bool:
	if inventory.size() >= max_slots:
		return false
	inventory.append(item_data)
	inventory_changed.emit()
	return true

func remove_from_inventory(index: int) -> void:
	if index >= 0 and index < inventory.size():
		inventory.remove_at(index)
		inventory_changed.emit()

func sell_item(index: int) -> void:
	if index >= 0 and index < inventory.size():
		var item = inventory[index]
		add_coins(item.get("value", 1))
		remove_from_inventory(index)

func sell_all() -> void:
	var total = 0
	for item in inventory:
		total += item.get("value", 1)
	inventory.clear()
	add_coins(total)
	inventory_changed.emit()

func get_upgrade_cost(upgrade_id: String) -> int:
	var config = upgrade_config.get(upgrade_id, {})
	var level = upgrades.get(upgrade_id, 0)
	return int(config.get("base", 100) * pow(config.get("mult", 2.0), level))

func get_upgrade_max(upgrade_id: String) -> int:
	return upgrade_config.get(upgrade_id, {}).get("max", 1)

func buy_upgrade(upgrade_id: String) -> bool:
	var level = upgrades.get(upgrade_id, 0)
	var max_lvl = get_upgrade_max(upgrade_id)
	if level >= max_lvl:
		return false
	var cost = get_upgrade_cost(upgrade_id)
	if not spend_coins(cost):
		return false
	upgrades[upgrade_id] = level + 1
	_apply_upgrade(upgrade_id)
	upgrade_purchased.emit(upgrade_id)
	return true

func _apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"bigger_bag":
			max_slots += 2
			inventory_changed.emit()
		"click_power":
			click_power += 1
		"lucky_find":
			luck_bonus += 0.03

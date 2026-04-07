extends Node

signal coins_changed(new_amount: int)
signal inventory_changed()
signal upgrade_purchased(upgrade_id: String)
signal sorted_changed()
signal ingots_changed()
signal notification(msg: String)

var coins: int = 0
var inventory: Array = []
var sorted_materials: Array = []
var ingots: Array = []
var max_slots: int = 8
var click_power: int = 1
var luck_bonus: float = 0.0
var smelt_speed_bonus: float = 0.0
var streak: int = 0
var total_sorted: int = 0
var correct_sorted: int = 0
var lifetime_coins: int = 0

var upgrades: Dictionary = {
	"bigger_bag": 0,
	"click_power": 0,
	"lucky_find": 0,
	"fast_furnace": 0,
	"sort_mastery": 0,
}

var upgrade_config: Dictionary = {
	"bigger_bag": {"base": 30, "mult": 1.7, "max": 8, "desc": "+2 inventory slots"},
	"click_power": {"base": 60, "mult": 2.0, "max": 5, "desc": "+1 scrap per click"},
	"lucky_find": {"base": 100, "mult": 2.2, "max": 6, "desc": "+3% rare chance"},
	"fast_furnace": {"base": 120, "mult": 1.9, "max": 8, "desc": "-15% smelt time"},
	"sort_mastery": {"base": 80, "mult": 2.0, "max": 8, "desc": "+10% sort value"},
}

# Sorting bins: which materials go where
var sort_bins: Dictionary = {
	"ferrous": ["bolt", "pipe"],
	"electronics": ["battery", "motor"],
	"non_ferrous": ["can", "cable"],
	"precious": ["gold"],
}

# Smelt configs
var smelt_config: Dictionary = {
	"can": {"time": 5.0, "mult": 2.0, "ingot": "Aluminum Ingot"},
	"bolt": {"time": 10.0, "mult": 2.5, "ingot": "Steel Ingot"},
	"pipe": {"time": 10.0, "mult": 2.5, "ingot": "Steel Ingot"},
	"cable": {"time": 8.0, "mult": 3.0, "ingot": "Copper Ingot"},
	"battery": {"time": 12.0, "mult": 2.0, "ingot": "Lead Ingot"},
	"motor": {"time": 15.0, "mult": 3.5, "ingot": "Circuit Board"},
	"gold": {"time": 20.0, "mult": 5.0, "ingot": "Gold Ingot"},
}

func add_coins(amount: int) -> void:
	coins += amount
	lifetime_coins += amount
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
	if total > 0:
		add_coins(total)
	inventory_changed.emit()

func try_sort(item_index: int, bin_id: String) -> bool:
	if item_index < 0 or item_index >= inventory.size():
		return false
	var item = inventory[item_index]
	var item_id = item.get("id", "")
	var accepted = sort_bins.get(bin_id, [])
	var correct = item_id in accepted
	total_sorted += 1
	if correct:
		correct_sorted += 1
		streak += 1
		var sort_bonus = 1.0 + upgrades.get("sort_mastery", 0) * 0.10
		var streak_bonus = 1.0 + min(streak * 0.05, 0.50)
		var sorted_value = int(item.get("value", 1) * 1.8 * sort_bonus * streak_bonus)
		var sorted_item = item.duplicate()
		sorted_item["sorted_value"] = sorted_value
		sorted_materials.append(sorted_item)
		remove_from_inventory(item_index)
		sorted_changed.emit()
		return true
	else:
		streak = 0
		remove_from_inventory(item_index)
		notification.emit("Wrong bin! Material lost.")
		return false

func add_ingot(ingot_data: Dictionary) -> void:
	ingots.append(ingot_data)
	ingots_changed.emit()

func sell_ingot(index: int) -> void:
	if index >= 0 and index < ingots.size():
		var ingot = ingots[index]
		add_coins(ingot.get("value", 1))
		ingots.remove_at(index)
		ingots_changed.emit()

func sell_all_ingots() -> void:
	var total = 0
	for ingot in ingots:
		total += ingot.get("value", 1)
	ingots.clear()
	if total > 0:
		add_coins(total)
	ingots_changed.emit()

func get_upgrade_cost(upgrade_id: String) -> int:
	var config = upgrade_config.get(upgrade_id, {})
	var level = upgrades.get(upgrade_id, 0)
	return int(config.get("base", 100) * pow(config.get("mult", 2.0), level))

func get_upgrade_max(upgrade_id: String) -> int:
	return upgrade_config.get(upgrade_id, {}).get("max", 1)

func buy_upgrade(upgrade_id: String) -> bool:
	var level = upgrades.get(upgrade_id, 0)
	if level >= get_upgrade_max(upgrade_id):
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
		"fast_furnace":
			smelt_speed_bonus += 0.15
		"sort_mastery":
			pass

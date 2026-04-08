extends Node

signal coins_changed(new_amount: int)
signal inventory_changed()
signal upgrade_purchased(upgrade_id: String)
signal sorted_changed()
signal ingots_changed()
signal notification(msg: String)
signal achievement_unlocked(id: String)
signal prestige_done(tokens: int)

var coins: int = 0
var inventory: Array = []
var sorted_materials: Array = []
var ingots: Array = []
var max_slots: int = 8
var click_power: int = 1
var luck_bonus: float = 0.0
var smelt_speed_bonus: float = 0.0
var streak: int = 0
var best_streak: int = 0
var total_sorted: int = 0
var correct_sorted: int = 0
var lifetime_coins: int = 0
var total_collected: int = 0
var total_smelted: int = 0
var forge_tokens: int = 0
var prestige_count: int = 0
var play_time: float = 0.0

var achievements_unlocked: Array = []
var achievements_config: Array = [
	{"id": "first_scrap", "name": "First Scrap", "desc": "Collect your first scrap", "check": "total_collected >= 1"},
	{"id": "hundred_coins", "name": "Pocket Change", "desc": "Earn 100 coins", "check": "lifetime_coins >= 100"},
	{"id": "thousand_coins", "name": "Scrap Dealer", "desc": "Earn 1,000 coins", "check": "lifetime_coins >= 1000"},
	{"id": "ten_k", "name": "Junk Mogul", "desc": "Earn 10,000 coins", "check": "lifetime_coins >= 10000"},
	{"id": "fifty_k", "name": "Forge Master", "desc": "Earn 50,000 coins", "check": "lifetime_coins >= 50000"},
	{"id": "first_sort", "name": "Sorted!", "desc": "Sort your first item correctly", "check": "correct_sorted >= 1"},
	{"id": "sort_streak_5", "name": "On a Roll", "desc": "Get a 5x sort streak", "check": "best_streak >= 5"},
	{"id": "sort_streak_10", "name": "Sort Machine", "desc": "Get a 10x sort streak", "check": "best_streak >= 10"},
	{"id": "first_smelt", "name": "Smelter", "desc": "Smelt your first ingot", "check": "total_smelted >= 1"},
	{"id": "ten_ingots", "name": "Ingot Factory", "desc": "Smelt 10 ingots", "check": "total_smelted >= 10"},
	{"id": "gold_find", "name": "Gold Rush", "desc": "Collect a Gold Part", "check": "has_found_gold == true"},
	{"id": "first_prestige", "name": "Meltdown!", "desc": "Prestige for the first time", "check": "prestige_count >= 1"},
	{"id": "full_inv", "name": "Hoarder", "desc": "Fill your inventory completely", "check": "inventory_full == true"},
	{"id": "collect_100", "name": "Scrap Pile", "desc": "Collect 100 items total", "check": "total_collected >= 100"},
	{"id": "play_30min", "name": "Dedicated", "desc": "Play for 30 minutes", "check": "play_time >= 1800"},
]

var has_found_gold: bool = false
var inventory_full: bool = false

var upgrades: Dictionary = {
	"bigger_bag": 0, "click_power": 0, "lucky_find": 0,
	"fast_furnace": 0, "sort_mastery": 0,
	"auto_sort": 0, "second_furnace": 0, "night_shift": 0,
}

var upgrade_config: Dictionary = {
	"bigger_bag": {"base": 30, "mult": 1.7, "max": 8, "desc": "+2 inventory slots"},
	"click_power": {"base": 60, "mult": 2.0, "max": 5, "desc": "+1 scrap per click"},
	"lucky_find": {"base": 100, "mult": 2.2, "max": 6, "desc": "+3% rare chance"},
	"fast_furnace": {"base": 120, "mult": 1.9, "max": 8, "desc": "-15% smelt time"},
	"sort_mastery": {"base": 80, "mult": 2.0, "max": 8, "desc": "+10% sort value"},
	"auto_sort": {"base": 5000, "mult": 1.0, "max": 1, "desc": "Auto-sort 85% accuracy"},
	"second_furnace": {"base": 2500, "mult": 1.0, "max": 1, "desc": "Second furnace slot"},
	"night_shift": {"base": 3000, "mult": 1.0, "max": 1, "desc": "Offline earnings 50%→75%"},
}

var sort_bins: Dictionary = {
	"ferrous": ["bolt", "pipe"],
	"electronics": ["battery", "motor"],
	"non_ferrous": ["can", "cable"],
	"precious": ["gold"],
}

var smelt_config: Dictionary = {
	"can": {"time": 5.0, "mult": 2.0, "ingot": "Aluminum Ingot"},
	"bolt": {"time": 10.0, "mult": 2.5, "ingot": "Steel Ingot"},
	"pipe": {"time": 10.0, "mult": 2.5, "ingot": "Steel Ingot"},
	"cable": {"time": 8.0, "mult": 3.0, "ingot": "Copper Ingot"},
	"battery": {"time": 12.0, "mult": 2.0, "ingot": "Lead Ingot"},
	"motor": {"time": 15.0, "mult": 3.5, "ingot": "Circuit Board"},
	"gold": {"time": 20.0, "mult": 5.0, "ingot": "Gold Ingot"},
}

func _process(delta: float) -> void:
	play_time += delta
	_check_achievements()
	# Auto-sort
	if upgrades.get("auto_sort", 0) > 0 and inventory.size() > 0:
		_auto_sort_tick(delta)

var _auto_sort_timer: float = 0.0
func _auto_sort_tick(delta: float) -> void:
	_auto_sort_timer += delta
	if _auto_sort_timer >= 3.0:
		_auto_sort_timer = 0.0
		if inventory.size() > 0:
			var item = inventory[0]
			var item_id = item.get("id", "")
			# Find correct bin
			var correct_bin = ""
			for bin_id in sort_bins:
				if item_id in sort_bins[bin_id]:
					correct_bin = bin_id
					break
			if correct_bin != "":
				# 85% accuracy
				if randf() < 0.85:
					try_sort(0, correct_bin)
				else:
					# Wrong sort
					var bins_list = sort_bins.keys()
					var wrong = bins_list[randi() % bins_list.size()]
					try_sort(0, wrong)

func add_coins(amount: int) -> void:
	var prestige_bonus = 1.0 + forge_tokens * 0.10
	var actual = int(amount * prestige_bonus)
	coins += actual
	lifetime_coins += actual
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false

func add_to_inventory(item_data: Dictionary) -> bool:
	if inventory.size() >= max_slots:
		inventory_full = true
		return false
	inventory.append(item_data)
	total_collected += 1
	if item_data.get("id", "") == "gold":
		has_found_gold = true
	if inventory.size() >= max_slots:
		inventory_full = true
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
		if streak > best_streak:
			best_streak = streak
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
	total_smelted += 1
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
		"auto_sort":
			notification.emit("Auto-Sorter activated! 85% accuracy")
		"second_furnace":
			notification.emit("Second furnace slot unlocked!")
		"night_shift":
			notification.emit("Night Shift active! 75% offline earnings")

# ---- PRESTIGE ----
func can_prestige() -> bool:
	return lifetime_coins >= 50000

func get_prestige_tokens() -> int:
	if lifetime_coins < 10000:
		return 0
	return int(log(lifetime_coins) / log(10) - 3)

func do_prestige() -> void:
	if not can_prestige():
		return
	var tokens = get_prestige_tokens()
	forge_tokens += tokens
	prestige_count += 1
	# Reset
	coins = 0
	inventory.clear()
	sorted_materials.clear()
	ingots.clear()
	max_slots = 8
	click_power = 1
	luck_bonus = 0.0
	smelt_speed_bonus = 0.0
	streak = 0
	# Reset upgrades but keep prestige-specific ones
	for key in upgrades:
		upgrades[key] = 0
	# Emit all signals
	coins_changed.emit(coins)
	inventory_changed.emit()
	sorted_changed.emit()
	ingots_changed.emit()
	prestige_done.emit(tokens)
	notification.emit("MELTDOWN! +%d Forge Tokens! (Total: %d)" % [tokens, forge_tokens])

# ---- ACHIEVEMENTS ----
func _check_achievements() -> void:
	for ach in achievements_config:
		if ach.id in achievements_unlocked:
			continue
		var expr = Expression.new()
		var err = expr.parse(ach.check, ["total_collected", "lifetime_coins", "correct_sorted",
			"best_streak", "total_smelted", "has_found_gold", "prestige_count",
			"inventory_full", "play_time"])
		if err != OK:
			continue
		var result = expr.execute([total_collected, lifetime_coins, correct_sorted,
			best_streak, total_smelted, has_found_gold, prestige_count,
			inventory_full, play_time])
		if result == true:
			achievements_unlocked.append(ach.id)
			achievement_unlocked.emit(ach.id)
			notification.emit("🏆 ACHIEVEMENT: %s" % ach.name)

func get_accuracy() -> int:
	if total_sorted == 0:
		return 0
	return int(float(correct_sorted) / total_sorted * 100.0)

func get_idle_rate() -> float:
	var rate = 0.0
	if upgrades.get("click_power", 0) >= 2:
		rate += 0.1
	if upgrades.get("auto_sort", 0) > 0:
		rate += 0.2
	var prestige_bonus = 1.0 + forge_tokens * 0.10
	return rate * prestige_bonus

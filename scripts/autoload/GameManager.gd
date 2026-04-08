extends Node

signal coins_changed(new_amount: int)
signal inventory_changed()
signal upgrade_purchased(upgrade_id: String)
signal sorted_changed()
signal ingots_changed()
signal notification(msg: String)
signal achievement_unlocked(id: String)
signal prestige_done(tokens: int)
signal ground_changed(skin_id: String)
signal tutorial_step(step: String)

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
var has_found_gold: bool = false
var inventory_full: bool = false
var current_ground: String = "default"
var tutorial_done: bool = false
var tutorial_current: int = 0
var notification_history: Array = []

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
	"second_furnace": {"base": 2500, "mult": 1.0, "max": 1, "desc": "+2 furnace queue slots"},
	"night_shift": {"base": 3000, "mult": 1.0, "max": 1, "desc": "Offline earnings 50%→75%"},
}

# Forge Token shop (prestige currency)
var forge_shop_config: Dictionary = {
	"income_boost": {"cost": 1, "max": 10, "desc": "+10% all income", "type": "permanent"},
	"rare_boost": {"cost": 2, "max": 5, "desc": "+5% rare spawn chance", "type": "permanent"},
	"start_coins": {"cost": 1, "max": 5, "desc": "Start with 500 coins after prestige", "type": "permanent"},
	"ground_rust": {"cost": 1, "max": 1, "desc": "Rusty Iron ground skin", "type": "cosmetic"},
	"ground_ash": {"cost": 2, "max": 1, "desc": "Volcanic Ash ground skin", "type": "cosmetic"},
	"ground_gold": {"cost": 3, "max": 1, "desc": "Golden Scrapyard ground skin", "type": "cosmetic"},
	"third_furnace": {"cost": 3, "max": 1, "desc": "Third furnace queue slot", "type": "permanent"},
	"auto_collect_2": {"cost": 2, "max": 1, "desc": "Auto-collect every 5s (was 10s)", "type": "permanent"},
}
var forge_purchases: Dictionary = {
	"income_boost": 0, "rare_boost": 0, "start_coins": 0,
	"ground_rust": 0, "ground_ash": 0, "ground_gold": 0,
	"third_furnace": 0, "auto_collect_2": 0,
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

var _tutorial_steps: Array = [
	"Click on scrap items to collect them!",
	"Open INV (📦) to see your items. Click to sell.",
	"Try SORT (♻) — select item, then click the right bin!",
	"Load sorted items into the FORGE (🔥) to smelt ingots.",
	"Buy upgrades in SHOP (🛒) to earn faster!",
	"Check STATS (📊) for achievements and prestige.",
]

func _process(delta: float) -> void:
	play_time += delta
	_check_achievements()
	if upgrades.get("auto_sort", 0) > 0 and inventory.size() > 0:
		_auto_sort_tick(delta)
	# Tutorial triggers
	if not tutorial_done:
		_check_tutorial()

var _auto_sort_timer: float = 0.0
func _auto_sort_tick(delta: float) -> void:
	_auto_sort_timer += delta
	if _auto_sort_timer >= 3.0:
		_auto_sort_timer = 0.0
		if inventory.size() > 0:
			var item = inventory[0]
			var item_id = item.get("id", "")
			var correct_bin = ""
			for bin_id in sort_bins:
				if item_id in sort_bins[bin_id]:
					correct_bin = bin_id
					break
			if correct_bin != "":
				if randf() < 0.85:
					try_sort(0, correct_bin)
				else:
					var bins_list = sort_bins.keys()
					try_sort(0, bins_list[randi() % bins_list.size()])

func _check_tutorial() -> void:
	if tutorial_current == 0 and total_collected == 0:
		tutorial_step.emit(_tutorial_steps[0])
		tutorial_current = 1
	elif tutorial_current == 1 and total_collected >= 3:
		tutorial_step.emit(_tutorial_steps[1])
		tutorial_current = 2
	elif tutorial_current == 2 and lifetime_coins >= 5:
		tutorial_step.emit(_tutorial_steps[2])
		tutorial_current = 3
	elif tutorial_current == 3 and correct_sorted >= 1:
		tutorial_step.emit(_tutorial_steps[3])
		tutorial_current = 4
	elif tutorial_current == 4 and total_smelted >= 1:
		tutorial_step.emit(_tutorial_steps[4])
		tutorial_current = 5
	elif tutorial_current == 5 and lifetime_coins >= 50:
		tutorial_step.emit(_tutorial_steps[5])
		tutorial_current = 6
		tutorial_done = true

func add_coins(amount: int) -> void:
	var prestige_bonus = 1.0 + forge_tokens * 0.10
	var income_bonus = 1.0 + forge_purchases.get("income_boost", 0) * 0.10
	var actual = int(amount * prestige_bonus * income_bonus)
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

func get_upgrade_cost(uid: String) -> int:
	var config = upgrade_config.get(uid, {})
	var level = upgrades.get(uid, 0)
	return int(config.get("base", 100) * pow(config.get("mult", 2.0), level))

func get_upgrade_max(uid: String) -> int:
	return upgrade_config.get(uid, {}).get("max", 1)

func buy_upgrade(uid: String) -> bool:
	var level = upgrades.get(uid, 0)
	if level >= get_upgrade_max(uid):
		return false
	var cost = get_upgrade_cost(uid)
	if not spend_coins(cost):
		return false
	upgrades[uid] = level + 1
	_apply_upgrade(uid)
	upgrade_purchased.emit(uid)
	return true

func _apply_upgrade(uid: String) -> void:
	match uid:
		"bigger_bag": max_slots += 2; inventory_changed.emit()
		"click_power": click_power += 1
		"lucky_find": luck_bonus += 0.03
		"fast_furnace": smelt_speed_bonus += 0.15
		"sort_mastery": pass
		"auto_sort": notification.emit("Auto-Sorter activated!")
		"second_furnace": notification.emit("Second furnace slot unlocked!")
		"night_shift": notification.emit("Night Shift active! 75% offline")

# ---- FORGE TOKEN SHOP ----
func buy_forge_item(item_id: String) -> bool:
	var config = forge_shop_config.get(item_id, {})
	var current = forge_purchases.get(item_id, 0)
	var max_lvl = config.get("max", 1)
	var cost = config.get("cost", 1)
	if current >= max_lvl or forge_tokens < cost:
		return false
	forge_tokens -= cost
	forge_purchases[item_id] = current + 1
	_apply_forge_purchase(item_id)
	notification.emit("Forge purchase: %s" % config.get("desc", ""))
	return true

func _apply_forge_purchase(item_id: String) -> void:
	match item_id:
		"income_boost": pass  # Applied in add_coins
		"rare_boost": luck_bonus += 0.05
		"start_coins": pass  # Applied in do_prestige
		"ground_rust": current_ground = "rust"; ground_changed.emit("rust")
		"ground_ash": current_ground = "ash"; ground_changed.emit("ash")
		"ground_gold": current_ground = "gold"; ground_changed.emit("gold")
		"third_furnace": pass  # Read by Furnace
		"auto_collect_2": pass  # Read by AutoCollector

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
	coins = 0
	# Start coins bonus
	var start_bonus = forge_purchases.get("start_coins", 0) * 500
	if start_bonus > 0:
		coins = start_bonus
	inventory.clear()
	sorted_materials.clear()
	ingots.clear()
	max_slots = 8
	click_power = 1
	smelt_speed_bonus = 0.0
	streak = 0
	# Reset coin upgrades but keep forge purchases
	for key in upgrades:
		upgrades[key] = 0
	# Re-apply forge permanent bonuses
	luck_bonus = forge_purchases.get("rare_boost", 0) * 0.05
	coins_changed.emit(coins)
	inventory_changed.emit()
	sorted_changed.emit()
	ingots_changed.emit()
	prestige_done.emit(tokens)
	notification.emit("MELTDOWN! +%d Forge Tokens! (Total: %d)" % [tokens, forge_tokens])

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
			notification.emit("🏆 %s" % ach.name)

func get_accuracy() -> int:
	if total_sorted == 0: return 0
	return int(float(correct_sorted) / total_sorted * 100.0)

func get_idle_rate() -> float:
	var rate = 0.0
	if upgrades.get("click_power", 0) >= 2: rate += 0.1
	if upgrades.get("auto_sort", 0) > 0: rate += 0.2
	var prestige_bonus = 1.0 + forge_tokens * 0.10
	var income_bonus = 1.0 + forge_purchases.get("income_boost", 0) * 0.10
	return rate * prestige_bonus * income_bonus

func add_notification(msg: String) -> void:
	notification_history.insert(0, {"msg": msg, "time": play_time})
	if notification_history.size() > 50:
		notification_history.pop_back()
	notification.emit(msg)

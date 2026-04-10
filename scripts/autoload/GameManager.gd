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

var achievements_unlocked: Array = []
var achievements_config: Array = [
	{"id": "first_scrap", "name": "First Scrap", "desc": "Collect first scrap", "check": "total_collected >= 1"},
	{"id": "hundred_coins", "name": "Pocket Change", "desc": "Earn 100 coins", "check": "lifetime_coins >= 100"},
	{"id": "thousand_coins", "name": "Scrap Dealer", "desc": "Earn 1000 coins", "check": "lifetime_coins >= 1000"},
	{"id": "ten_k", "name": "Junk Mogul", "desc": "Earn 10K coins", "check": "lifetime_coins >= 10000"},
	{"id": "fifty_k", "name": "Forge Master", "desc": "Earn 50K coins", "check": "lifetime_coins >= 50000"},
	{"id": "first_sort", "name": "Sorted!", "desc": "Sort correctly", "check": "correct_sorted >= 1"},
	{"id": "sort_streak_5", "name": "On a Roll", "desc": "5x streak", "check": "best_streak >= 5"},
	{"id": "sort_streak_10", "name": "Sort Machine", "desc": "10x streak", "check": "best_streak >= 10"},
	{"id": "first_smelt", "name": "Smelter", "desc": "Smelt first ingot", "check": "total_smelted >= 1"},
	{"id": "ten_ingots", "name": "Ingot Factory", "desc": "Smelt 10", "check": "total_smelted >= 10"},
	{"id": "gold_find", "name": "Gold Rush", "desc": "Find Gold", "check": "has_found_gold == true"},
	{"id": "first_prestige", "name": "Meltdown!", "desc": "Prestige once", "check": "prestige_count >= 1"},
	{"id": "full_inv", "name": "Hoarder", "desc": "Fill inventory", "check": "inventory_full == true"},
	{"id": "collect_100", "name": "Scrap Pile", "desc": "Collect 100", "check": "total_collected >= 100"},
	{"id": "play_30min", "name": "Dedicated", "desc": "Play 30 min", "check": "play_time >= 1800"},
]

var upgrades: Dictionary = {
	"bigger_bag": 0, "click_power": 0, "lucky_find": 0,
	"fast_furnace": 0, "sort_mastery": 0,
	"auto_sort": 0, "second_furnace": 0, "night_shift": 0,
}
var upgrade_config: Dictionary = {
	"bigger_bag": {"base": 30, "mult": 1.7, "max": 8, "desc": "+2 slots"},
	"click_power": {"base": 60, "mult": 2.0, "max": 5, "desc": "+1/click"},
	"lucky_find": {"base": 100, "mult": 2.2, "max": 6, "desc": "+3% rare"},
	"fast_furnace": {"base": 120, "mult": 1.9, "max": 8, "desc": "-15% time"},
	"sort_mastery": {"base": 80, "mult": 2.0, "max": 8, "desc": "+10% sort val"},
	"auto_sort": {"base": 5000, "mult": 1.0, "max": 1, "desc": "Auto-sort"},
	"second_furnace": {"base": 2500, "mult": 1.0, "max": 1, "desc": "+2 queue"},
	"night_shift": {"base": 3000, "mult": 1.0, "max": 1, "desc": "75% offline"},
}
var forge_shop_config: Dictionary = {
	"income_boost": {"cost": 1, "max": 10, "desc": "+10% income"},
	"rare_boost": {"cost": 2, "max": 5, "desc": "+5% rare"},
	"start_coins": {"cost": 1, "max": 5, "desc": "Start 500c"},
	"ground_rust": {"cost": 1, "max": 1, "desc": "Rusty ground"},
	"ground_ash": {"cost": 2, "max": 1, "desc": "Ash ground"},
	"ground_gold": {"cost": 3, "max": 1, "desc": "Gold ground"},
	"third_furnace": {"cost": 3, "max": 1, "desc": "3rd furnace"},
	"auto_collect_2": {"cost": 2, "max": 1, "desc": "Collect 5s"},
}
var forge_purchases: Dictionary = {
	"income_boost": 0, "rare_boost": 0, "start_coins": 0,
	"ground_rust": 0, "ground_ash": 0, "ground_gold": 0,
	"third_furnace": 0, "auto_collect_2": 0,
}
var sort_bins: Dictionary = {
	"ferrous": ["bolt", "pipe"], "electronics": ["battery", "motor", "chip"],
	"non_ferrous": ["can", "cable", "coil"], "precious": ["gold", "crystal"], "mechanical": ["gear"],
}
var smelt_config: Dictionary = {
	"can": {"time": 5.0, "mult": 2.0, "ingot": "Aluminum Ingot"},
	"bolt": {"time": 10.0, "mult": 2.5, "ingot": "Steel Ingot"},
	"pipe": {"time": 10.0, "mult": 2.5, "ingot": "Steel Ingot"},
	"cable": {"time": 8.0, "mult": 3.0, "ingot": "Copper Ingot"},
	"battery": {"time": 12.0, "mult": 2.0, "ingot": "Lead Ingot"},
	"motor": {"time": 15.0, "mult": 3.5, "ingot": "Circuit Board"},
	"gold": {"time": 20.0, "mult": 5.0, "ingot": "Gold Ingot"},
	"chip": {"time": 10.0, "mult": 2.5, "ingot": "Silicon Wafer"},
	"coil": {"time": 7.0, "mult": 2.8, "ingot": "Copper Wire"},
	"gear": {"time": 14.0, "mult": 3.5, "ingot": "Titanium Rod"},
	"crystal": {"time": 25.0, "mult": 6.0, "ingot": "Forge Shard"},
}

var _auto_sort_timer: float = 0.0

func _process(delta: float) -> void:
	play_time += delta
	_check_achievements()
	if upgrades.get("auto_sort", 0) > 0 and inventory.size() > 0:
		_auto_sort_timer += delta
		if _auto_sort_timer >= 3.0:
			_auto_sort_timer = 0.0
			_do_auto_sort()

func _do_auto_sort() -> void:
	var item = inventory[0]
	var correct_bin = ""
	for bin_id in sort_bins:
		if item.get("id", "") in sort_bins[bin_id]:
			correct_bin = bin_id
			break
	if correct_bin != "":
		if randf() < 0.85:
			try_sort(0, correct_bin)
		else:
			var keys = sort_bins.keys()
			try_sort(0, keys[randi() % keys.size()])

func add_coins(amount: int) -> void:
	var bonus: float = (1.0 + forge_tokens * 0.1) * (1.0 + forge_purchases.get("income_boost", 0) * 0.1)
	var actual: int = int(amount * bonus)
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
		add_coins(inventory[index].get("value", 1))
		remove_from_inventory(index)

func sell_all() -> void:
	var total: int = 0
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
	var correct = item.get("id", "") in sort_bins.get(bin_id, [])
	total_sorted += 1
	if correct:
		correct_sorted += 1
		streak += 1
		if streak > best_streak:
			best_streak = streak
		var sv: int = int(item.get("value", 1) * 1.8 * (1.0 + upgrades.get("sort_mastery", 0) * 0.1) * (1.0 + minf(streak * 0.05, 0.5)))
		var si = item.duplicate()
		si["sorted_value"] = sv
		sorted_materials.append(si)
		remove_from_inventory(item_index)
		sorted_changed.emit()
		return true
	else:
		streak = 0
		remove_from_inventory(item_index)
		notification.emit("Wrong bin! Lost.")
		return false

func add_ingot(d: Dictionary) -> void:
	ingots.append(d)
	total_smelted += 1
	ingots_changed.emit()

func sell_ingot(index: int) -> void:
	if index >= 0 and index < ingots.size():
		add_coins(ingots[index].get("value", 1))
		ingots.remove_at(index)
		ingots_changed.emit()

func sell_all_ingots() -> void:
	var t: int = 0
	for ig in ingots:
		t += ig.get("value", 1)
	ingots.clear()
	if t > 0:
		add_coins(t)
	ingots_changed.emit()

func get_upgrade_cost(uid: String) -> int:
	var c = upgrade_config.get(uid, {})
	return int(c.get("base", 100) * pow(c.get("mult", 2.0), upgrades.get(uid, 0)))

func get_upgrade_max(uid: String) -> int:
	return upgrade_config.get(uid, {}).get("max", 1)

func buy_upgrade(uid: String) -> bool:
	if upgrades.get(uid, 0) >= get_upgrade_max(uid):
		return false
	if not spend_coins(get_upgrade_cost(uid)):
		return false
	upgrades[uid] = upgrades.get(uid, 0) + 1
	match uid:
		"bigger_bag": max_slots += 2; inventory_changed.emit()
		"click_power": click_power += 1
		"lucky_find": luck_bonus += 0.03
		"fast_furnace": smelt_speed_bonus += 0.15
	upgrade_purchased.emit(uid)
	return true

func buy_forge_item(item_id: String) -> bool:
	var c = forge_shop_config.get(item_id, {})
	var cur = forge_purchases.get(item_id, 0)
	if cur >= c.get("max", 1) or forge_tokens < c.get("cost", 1):
		return false
	forge_tokens -= c.cost
	forge_purchases[item_id] = cur + 1
	match item_id:
		"rare_boost": luck_bonus += 0.05
		"ground_rust": current_ground = "rust"; ground_changed.emit("rust")
		"ground_ash": current_ground = "ash"; ground_changed.emit("ash")
		"ground_gold": current_ground = "gold"; ground_changed.emit("gold")
	notification.emit("Forge: %s" % c.get("desc", ""))
	return true

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
	coins = forge_purchases.get("start_coins", 0) * 500
	inventory.clear()
	sorted_materials.clear()
	ingots.clear()
	max_slots = 8
	click_power = 1
	smelt_speed_bonus = 0.0
	streak = 0
	for key in upgrades:
		upgrades[key] = 0
	luck_bonus = forge_purchases.get("rare_boost", 0) * 0.05
	coins_changed.emit(coins)
	inventory_changed.emit()
	sorted_changed.emit()
	ingots_changed.emit()
	prestige_done.emit(tokens)
	notification.emit("MELTDOWN! +%d tokens (Total: %d)" % [tokens, forge_tokens])

func _check_achievements() -> void:
	for ach in achievements_config:
		if ach.id in achievements_unlocked:
			continue
		var expr = Expression.new()
		if expr.parse(ach.check, ["total_collected","lifetime_coins","correct_sorted","best_streak","total_smelted","has_found_gold","prestige_count","inventory_full","play_time"]) != OK:
			continue
		if expr.execute([total_collected,lifetime_coins,correct_sorted,best_streak,total_smelted,has_found_gold,prestige_count,inventory_full,play_time]) == true:
			achievements_unlocked.append(ach.id)
			achievement_unlocked.emit(ach.id)
			notification.emit("🏆 %s" % ach.name)

func get_accuracy() -> int:
	if total_sorted == 0:
		return 0
	return int(float(correct_sorted) / float(total_sorted) * 100.0)

func get_idle_rate() -> float:
	var r: float = 0.0
	if upgrades.get("click_power", 0) >= 2:
		r += 0.1
	if upgrades.get("auto_sort", 0) > 0:
		r += 0.2
	return r * (1.0 + forge_tokens * 0.1) * (1.0 + forge_purchases.get("income_boost", 0) * 0.1)

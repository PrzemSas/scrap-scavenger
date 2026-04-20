extends Node

const SAVE_PATH = "user://savegame.json"
var _timer: float = 0.0

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 60.0:
		_timer = 0.0
		save_game()

func _get_crafted() -> Array:
	var cm := get_node_or_null("/root/CraftingManager")
	if cm: return cm.get("crafted_items") if cm.get("crafted_items") != null else []
	return []

func save_game() -> void:
	var d = {
		"coins": GameManager.coins, "lifetime_coins": GameManager.lifetime_coins,
		"inventory": GameManager.inventory, "sorted_materials": GameManager.sorted_materials,
		"ingots": GameManager.ingots, "max_slots": GameManager.max_slots,
		"click_power": GameManager.click_power, "luck_bonus": GameManager.luck_bonus,
		"smelt_speed_bonus": GameManager.smelt_speed_bonus, "upgrades": GameManager.upgrades,
		"streak": GameManager.streak, "best_streak": GameManager.best_streak,
		"total_sorted": GameManager.total_sorted, "correct_sorted": GameManager.correct_sorted,
		"total_collected": GameManager.total_collected, "total_smelted": GameManager.total_smelted,
		"has_found_gold": GameManager.has_found_gold, "forge_tokens": GameManager.forge_tokens,
		"prestige_count": GameManager.prestige_count, "play_time": GameManager.play_time,
		"achievements": GameManager.achievements_unlocked,
		"forge_purchases": GameManager.forge_purchases,
		"current_ground": GameManager.current_ground,
		"total_crafted": GameManager.total_crafted,
		"scrap_crown_crafted": GameManager.scrap_crown_crafted,
		"building_materials": GameManager.building_materials,
		"best_daily_streak": GameManager.best_daily_streak,
		"best_leaderboard_rank": GameManager.best_leaderboard_rank,
		"forge_stage": GameManager.forge_stage,
		"scrap_value_bonus": GameManager.scrap_value_bonus,
		"combo_cap_bonus": GameManager.combo_cap_bonus,
		"detect_range_bonus": GameManager.detect_range_bonus,
		"ingot_value_bonus": GameManager.ingot_value_bonus,
		"worker_speed_bonus": GameManager.worker_speed_bonus,
		"wasteland_luck_bonus": GameManager.wasteland_luck_bonus,
		"timestamp": Time.get_unix_time_from_system(),
		"crafted_items": _get_crafted(),
	}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(d, "\t"))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return
	var d = json.data
	GameManager.coins = d.get("coins", 0)
	GameManager.lifetime_coins = d.get("lifetime_coins", 0)
	GameManager.inventory = d.get("inventory", [])
	GameManager.sorted_materials = d.get("sorted_materials", [])
	GameManager.ingots = d.get("ingots", [])
	GameManager.max_slots = d.get("max_slots", 8)
	GameManager.click_power = d.get("click_power", 1)
	GameManager.luck_bonus = d.get("luck_bonus", 0.0)
	GameManager.smelt_speed_bonus = d.get("smelt_speed_bonus", 0.0)
	GameManager.upgrades = d.get("upgrades", GameManager.upgrades)
	GameManager.streak = d.get("streak", 0)
	GameManager.best_streak = d.get("best_streak", 0)
	GameManager.total_sorted = d.get("total_sorted", 0)
	GameManager.correct_sorted = d.get("correct_sorted", 0)
	GameManager.total_collected = d.get("total_collected", 0)
	GameManager.total_smelted = d.get("total_smelted", 0)
	GameManager.has_found_gold = d.get("has_found_gold", false)
	GameManager.forge_tokens = d.get("forge_tokens", 0)
	GameManager.prestige_count = d.get("prestige_count", 0)
	GameManager.play_time = d.get("play_time", 0.0)
	GameManager.achievements_unlocked = d.get("achievements", [])
	GameManager.forge_purchases = d.get("forge_purchases", GameManager.forge_purchases)
	GameManager.current_ground = d.get("current_ground", "default")
	GameManager.total_crafted = d.get("total_crafted", 0)
	GameManager.scrap_crown_crafted = d.get("scrap_crown_crafted", false)
	var bm = d.get("building_materials", {})
	for k in GameManager.building_materials: GameManager.building_materials[k] = bm.get(k, 0)
	GameManager.best_daily_streak = d.get("best_daily_streak", 0)
	GameManager.best_leaderboard_rank = d.get("best_leaderboard_rank", 999)
	GameManager.forge_stage = d.get("forge_stage", 0)
	GameManager.scrap_value_bonus = d.get("scrap_value_bonus", 0.0)
	GameManager.combo_cap_bonus = d.get("combo_cap_bonus", 0.0)
	GameManager.detect_range_bonus = d.get("detect_range_bonus", 0.0)
	GameManager.ingot_value_bonus = d.get("ingot_value_bonus", 0.0)
	GameManager.worker_speed_bonus = d.get("worker_speed_bonus", 0.0)
	GameManager.wasteland_luck_bonus = d.get("wasteland_luck_bonus", 0.0)
	var cm := get_node_or_null("/root/CraftingManager")
	if cm: cm.set("crafted_items", d.get("crafted_items", []))
	GameManager.coins_changed.emit(GameManager.coins)
	GameManager.inventory_changed.emit()
	GameManager.sorted_changed.emit()
	GameManager.ingots_changed.emit()
	var ts = d.get("timestamp", 0.0)
	if ts > 0:
		var off = clamp(Time.get_unix_time_from_system() - ts, 0, 86400)
		if off > 60:
			var eff: float = 0.75 if GameManager.upgrades.get("night_shift", 0) > 0 else 0.5
			var oc: int = int(GameManager.get_idle_rate() * off * eff)
			if oc > 0:
				GameManager.add_coins(oc)
				GameManager.notification.emit("Welcome back! +%dc" % oc)

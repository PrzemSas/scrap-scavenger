extends Node

const SAVE_PATH = "user://savegame.json"
const AUTOSAVE_INTERVAL = 60.0
var _timer: float = 0.0

func _ready() -> void:
	load_game()

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= AUTOSAVE_INTERVAL:
		_timer = 0.0
		save_game()

func save_game() -> void:
	var data = {
		"coins": GameManager.coins,
		"lifetime_coins": GameManager.lifetime_coins,
		"inventory": GameManager.inventory,
		"sorted_materials": GameManager.sorted_materials,
		"ingots": GameManager.ingots,
		"max_slots": GameManager.max_slots,
		"click_power": GameManager.click_power,
		"luck_bonus": GameManager.luck_bonus,
		"smelt_speed_bonus": GameManager.smelt_speed_bonus,
		"upgrades": GameManager.upgrades,
		"streak": GameManager.streak,
		"best_streak": GameManager.best_streak,
		"total_sorted": GameManager.total_sorted,
		"correct_sorted": GameManager.correct_sorted,
		"total_collected": GameManager.total_collected,
		"total_smelted": GameManager.total_smelted,
		"has_found_gold": GameManager.has_found_gold,
		"forge_tokens": GameManager.forge_tokens,
		"prestige_count": GameManager.prestige_count,
		"play_time": GameManager.play_time,
		"achievements": GameManager.achievements_unlocked,
		"timestamp": Time.get_unix_time_from_system(),
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
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
	# Emit signals
	GameManager.coins_changed.emit(GameManager.coins)
	GameManager.inventory_changed.emit()
	GameManager.sorted_changed.emit()
	GameManager.ingots_changed.emit()
	# Offline earnings
	var saved_time = d.get("timestamp", 0.0)
	if saved_time > 0:
		var offline_sec = clamp(Time.get_unix_time_from_system() - saved_time, 0, 86400)
		if offline_sec > 60:
			var idle_rate = GameManager.get_idle_rate()
			var efficiency = 0.75 if GameManager.upgrades.get("night_shift", 0) > 0 else 0.50
			var offline_coins = int(idle_rate * offline_sec * efficiency)
			if offline_coins > 0:
				GameManager.add_coins(offline_coins)
				var mins = int(offline_sec / 60)
				GameManager.notification.emit("Welcome back! +%d coins (%d min)" % [offline_coins, mins])

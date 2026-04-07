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
		"total_sorted": GameManager.total_sorted,
		"correct_sorted": GameManager.correct_sorted,
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
	var data = json.data
	GameManager.coins = data.get("coins", 0)
	GameManager.lifetime_coins = data.get("lifetime_coins", 0)
	GameManager.inventory = data.get("inventory", [])
	GameManager.sorted_materials = data.get("sorted_materials", [])
	GameManager.ingots = data.get("ingots", [])
	GameManager.max_slots = data.get("max_slots", 8)
	GameManager.click_power = data.get("click_power", 1)
	GameManager.luck_bonus = data.get("luck_bonus", 0.0)
	GameManager.smelt_speed_bonus = data.get("smelt_speed_bonus", 0.0)
	GameManager.upgrades = data.get("upgrades", GameManager.upgrades)
	GameManager.streak = data.get("streak", 0)
	GameManager.total_sorted = data.get("total_sorted", 0)
	GameManager.correct_sorted = data.get("correct_sorted", 0)
	GameManager.coins_changed.emit(GameManager.coins)
	GameManager.inventory_changed.emit()
	GameManager.sorted_changed.emit()
	GameManager.ingots_changed.emit()
	# Offline earnings
	var saved_time = data.get("timestamp", 0.0)
	if saved_time > 0:
		var offline_sec = clamp(Time.get_unix_time_from_system() - saved_time, 0, 86400)
		if offline_sec > 60:
			var idle_rate = 0.1 if GameManager.upgrades.get("click_power", 0) > 0 else 0.0
			var offline_coins = int(idle_rate * offline_sec * 0.5)
			if offline_coins > 0:
				GameManager.add_coins(offline_coins)
				var mins = int(offline_sec / 60)
				GameManager.notification.emit("Welcome back! Earned %d coins in %d min" % [offline_coins, mins])

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

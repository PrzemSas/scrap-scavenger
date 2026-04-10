extends Node

signal leaderboard_updated

const SAVE_PATH = "user://leaderboard.json"
const MAX_ENTRIES = 10
const DEFAULT_NAME = "SCRAPPER"

var entries: Array = []

func _ready() -> void:
	_load()
	GameManager.prestige_done.connect(func(_t): _auto_submit())

func _auto_submit() -> void:
	submit_score(DEFAULT_NAME)

func submit_score(player_name: String) -> int:
	var entry = {
		"name": player_name.left(12).to_upper(),
		"lifetime_coins": GameManager.lifetime_coins,
		"prestige_count": GameManager.prestige_count,
		"play_time": int(GameManager.play_time),
		"timestamp": int(Time.get_unix_time_from_system()),
	}
	entries.append(entry)
	entries.sort_custom(func(a, b): return a.lifetime_coins > b.lifetime_coins)
	if entries.size() > MAX_ENTRIES:
		entries.resize(MAX_ENTRIES)
	_save()
	var rank = get_rank(entry.lifetime_coins)
	GameManager.best_leaderboard_rank = mini(GameManager.best_leaderboard_rank, rank)
	leaderboard_updated.emit()
	return rank

func get_rank(coins: int) -> int:
	for i in entries.size():
		if entries[i].get("lifetime_coins", 0) <= coins:
			return i + 1
	return entries.size() + 1

func get_current_rank() -> int:
	return get_rank(GameManager.lifetime_coins)

func _save() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(entries, "\t"))

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK and json.data is Array:
		entries = json.data

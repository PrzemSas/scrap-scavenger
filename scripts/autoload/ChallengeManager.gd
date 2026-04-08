extends Node

signal challenge_updated(challenge: Dictionary)
signal challenge_completed(challenge: Dictionary)

var current_challenge: Dictionary = {}
var _check_timer: float = 0.0
var completed_today: int = 0

var challenge_templates: Array = [
	{"type": "collect", "target": 20, "reward": 200, "desc": "Collect %d scrap items", "track": "total_collected"},
	{"type": "collect", "target": 50, "reward": 500, "desc": "Collect %d scrap items", "track": "total_collected"},
	{"type": "sort", "target": 10, "reward": 300, "desc": "Sort %d items correctly", "track": "correct_sorted"},
	{"type": "sort", "target": 25, "reward": 600, "desc": "Sort %d items correctly", "track": "correct_sorted"},
	{"type": "smelt", "target": 5, "reward": 400, "desc": "Smelt %d ingots", "track": "total_smelted"},
	{"type": "smelt", "target": 15, "reward": 800, "desc": "Smelt %d ingots", "track": "total_smelted"},
	{"type": "coins", "target": 500, "reward": 150, "desc": "Earn %d coins", "track": "lifetime_coins"},
	{"type": "coins", "target": 2000, "reward": 400, "desc": "Earn %d coins", "track": "lifetime_coins"},
	{"type": "streak", "target": 5, "reward": 250, "desc": "Get a %dx sort streak", "track": "best_streak"},
	{"type": "streak", "target": 8, "reward": 500, "desc": "Get a %dx sort streak", "track": "best_streak"},
]

func _ready() -> void:
	_generate_challenge()

func _process(delta: float) -> void:
	if current_challenge.is_empty():
		return
	_check_timer += delta
	if _check_timer >= 2.0:
		_check_timer = 0.0
		_check_progress()

func _generate_challenge() -> void:
	var template = challenge_templates[randi() % challenge_templates.size()]
	current_challenge = {
		"desc": template.desc % template.target,
		"target": template.target,
		"reward": template.reward,
		"track": template.track,
		"start_value": _get_tracked_value(template.track),
		"completed": false,
	}
	challenge_updated.emit(current_challenge)

func _check_progress() -> void:
	if current_challenge.get("completed", false):
		return
	var current_val = _get_tracked_value(current_challenge.track)
	var start_val = current_challenge.get("start_value", 0)
	var target = current_challenge.get("target", 0)
	var progress = current_val - start_val
	if progress >= target:
		current_challenge.completed = true
		var reward = current_challenge.get("reward", 0)
		GameManager.add_coins(reward)
		completed_today += 1
		GameManager.notification.emit("🎯 CHALLENGE DONE! +%dc" % reward)
		AudioManager.play_achievement()
		challenge_completed.emit(current_challenge)
		# Generate next after delay
		get_tree().create_timer(5.0).timeout.connect(_generate_challenge)
	challenge_updated.emit(current_challenge)

func _get_tracked_value(track: String) -> int:
	match track:
		"total_collected": return GameManager.total_collected
		"correct_sorted": return GameManager.correct_sorted
		"total_smelted": return GameManager.total_smelted
		"lifetime_coins": return GameManager.lifetime_coins
		"best_streak": return GameManager.best_streak
	return 0

func get_progress() -> int:
	if current_challenge.is_empty():
		return 0
	var current_val = _get_tracked_value(current_challenge.track)
	var start_val = current_challenge.get("start_value", 0)
	return current_val - start_val

func get_target() -> int:
	return current_challenge.get("target", 1)

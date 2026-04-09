extends Node

signal challenge_updated(challenge: Dictionary)

var current_challenge: Dictionary = {}
var _timer: float = 0.0

var templates: Array = [
	{"target": 20, "reward": 200, "desc": "Collect %d items", "track": "total_collected"},
	{"target": 10, "reward": 300, "desc": "Sort %d items", "track": "correct_sorted"},
	{"target": 5, "reward": 400, "desc": "Smelt %d ingots", "track": "total_smelted"},
	{"target": 500, "reward": 150, "desc": "Earn %d coins", "track": "lifetime_coins"},
]

func _ready() -> void:
	_generate()

func _process(delta: float) -> void:
	if current_challenge.is_empty():
		return
	_timer += delta
	if _timer >= 2.0:
		_timer = 0.0
		_check()

func _generate() -> void:
	var t = templates[randi() % templates.size()]
	current_challenge = {"desc": t.desc % t.target, "target": t.target, "reward": t.reward, "track": t.track, "start": _val(t.track), "done": false}
	challenge_updated.emit(current_challenge)

func _check() -> void:
	if current_challenge.get("done", false):
		return
	if get_progress() >= current_challenge.target:
		current_challenge.done = true
		GameManager.add_coins(current_challenge.reward)
		GameManager.notification.emit("🎯 CHALLENGE! +%dc" % current_challenge.reward)
		AudioManager.play_achievement()
		challenge_updated.emit(current_challenge)
		get_tree().create_timer(5.0).timeout.connect(_generate)
	else:
		challenge_updated.emit(current_challenge)

func get_progress() -> int:
	return _val(current_challenge.get("track", "")) - current_challenge.get("start", 0)

func get_target() -> int:
	return current_challenge.get("target", 1)

func _val(track: String) -> int:
	match track:
		"total_collected": return GameManager.total_collected
		"correct_sorted": return GameManager.correct_sorted
		"total_smelted": return GameManager.total_smelted
		"lifetime_coins": return GameManager.lifetime_coins
	return 0

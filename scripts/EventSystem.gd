extends Node

var _timer: float = 0.0
var _next: float = 120.0
var _active: bool = false

var events: Array = [
	{"msg": "🔥 SCRAP RUSH! 2x value 30s!", "bonus": 2.0, "dur": 30.0},
	{"msg": "⭐ RARE STORM! Rarity boost 20s!", "bonus": 1.5, "dur": 20.0},
	{"msg": "💰 GOLD FEVER! 3x value 15s!", "bonus": 3.0, "dur": 15.0},
	{"msg": "⚡ LIGHTNING! 1.5x value 45s!", "bonus": 1.5, "dur": 45.0},
]

func _process(delta: float) -> void:
	if _active:
		return
	_timer += delta
	if _timer >= _next:
		_timer = 0.0
		_next = randf_range(90.0, 180.0)
		_trigger()

func _trigger() -> void:
	var ev = events[randi() % events.size()]
	_active = true
	var sm = get_tree().current_scene.get_node_or_null("SpawnManager")
	if sm and sm.has_method("start_event"):
		sm.start_event(ev.bonus, ev.dur, ev.msg)
	get_tree().create_timer(ev.dur).timeout.connect(func(): _active = false)

extends Node

signal combo_changed(count: int, multiplier: float)

var combo_count: int = 0
var combo_timer: float = 0.0
const COMBO_WINDOW: float = 2.0  # seconds to keep combo alive
const MAX_COMBO: int = 20

func _ready() -> void:
	GameManager.coins_changed.connect(_on_action)

func _on_action(_coins: int) -> void:
	combo_count = min(combo_count + 1, MAX_COMBO)
	combo_timer = COMBO_WINDOW
	combo_changed.emit(combo_count, get_multiplier())

func _process(delta: float) -> void:
	if combo_count > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			combo_changed.emit(0, 1.0)

func get_multiplier() -> float:
	if combo_count < 3:
		return 1.0
	elif combo_count < 6:
		return 1.2
	elif combo_count < 10:
		return 1.5
	elif combo_count < 15:
		return 2.0
	else:
		return 3.0

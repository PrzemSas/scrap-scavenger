extends Node
@export var zone: String = "junkyard"
func _ready() -> void:
	AudioManager._current_zone = ""
	AudioManager.play_zone(zone)

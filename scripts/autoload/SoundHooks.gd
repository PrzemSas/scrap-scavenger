extends Node

func _ready() -> void:
	GameManager.upgrade_purchased.connect(func(_id): AudioManager.play_upgrade())
	GameManager.achievement_unlocked.connect(func(_id): AudioManager.play_achievement())
	GameManager.prestige_done.connect(func(_t): AudioManager.play_prestige())
	GameManager.notification.connect(_on_notif)

func _on_notif(msg: String) -> void:
	if "Wrong" in msg or "full" in msg:
		AudioManager.play_error()

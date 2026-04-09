extends Node
func _ready() -> void:
	GameManager.upgrade_purchased.connect(func(_id): AudioManager.play_upgrade())
	GameManager.achievement_unlocked.connect(func(_id): AudioManager.play_achievement())
	GameManager.prestige_done.connect(func(_t): AudioManager.play_prestige())

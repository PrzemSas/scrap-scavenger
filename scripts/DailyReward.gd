extends Control

@onready var title_label: Label = $Panel/VBox/Title
@onready var reward_label: Label = $Panel/VBox/Reward
@onready var claim_btn: Button = $Panel/VBox/ClaimBtn
@onready var streak_label: Label = $Panel/VBox/Streak

var daily_rewards: Array = [100, 200, 300, 500, 800, 1200, 2000]
var login_streak: int = 0
var last_claim_day: int = 0

func _ready() -> void:
	visible = false
	claim_btn.pressed.connect(_claim)
	# Check if reward available
	_load_daily()
	var today = _get_day()
	if today != last_claim_day:
		_show_reward()

func _get_day() -> int:
	var dict = Time.get_datetime_dict_from_system()
	return dict.year * 400 + dict.month * 32 + dict.day

func _load_daily() -> void:
	if not FileAccess.file_exists("user://daily.json"):
		return
	var f = FileAccess.open("user://daily.json", FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK:
		login_streak = json.data.get("streak", 0)
		last_claim_day = json.data.get("last_day", 0)

func _save_daily() -> void:
	var f = FileAccess.open("user://daily.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"streak": login_streak, "last_day": last_claim_day}))

func _show_reward() -> void:
	visible = true
	var today = _get_day()
	if today == last_claim_day + 1:
		login_streak = min(login_streak + 1, daily_rewards.size())
	elif today > last_claim_day + 1:
		login_streak = 1
	else:
		login_streak = max(login_streak, 1)
	var idx = min(login_streak - 1, daily_rewards.size() - 1)
	var reward = daily_rewards[idx]
	title_label.text = "DAILY REWARD"
	reward_label.text = "+%d COINS" % reward
	streak_label.text = "Day %d streak" % login_streak
	claim_btn.text = "CLAIM"
	claim_btn.disabled = false

func _claim() -> void:
	var idx = min(login_streak - 1, daily_rewards.size() - 1)
	var reward = daily_rewards[idx]
	GameManager.add_coins(reward)
	AudioManager.play_achievement()
	GameManager.notification.emit("Daily reward: +%dc (Day %d)" % [reward, login_streak])
	last_claim_day = _get_day()
	_save_daily()
	claim_btn.text = "✓ CLAIMED"
	claim_btn.disabled = true
	get_tree().create_timer(2.0).timeout.connect(func(): visible = false)

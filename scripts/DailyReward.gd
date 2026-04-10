extends Control

@onready var streak_label: Label = $Panel/VBox/StreakLabel
@onready var day_grid: GridContainer = $Panel/VBox/DayGrid
@onready var reward_label: Label = $Panel/VBox/RewardLabel
@onready var claim_btn: Button = $Panel/VBox/ClaimBtn
@onready var close_btn: Button = $Panel/VBox/TitleBar/CloseBtn

var reward_schedule: Array = [
	{"type":"coins","amount":200,"label":"200c"},
	{"type":"coins","amount":400,"label":"400c"},
	{"type":"token","amount":1,"label":"1🔥"},
	{"type":"coins","amount":600,"label":"600c"},
	{"type":"coins","amount":800,"label":"800c"},
	{"type":"token","amount":2,"label":"2🔥"},
	{"type":"both","coins":1500,"tokens":1,"label":"1500c\n+1🔥"},
]

var login_streak: int = 0
var best_daily_streak: int = 0
var last_claim_day: int = 0
var claimed_today: bool = false

func _ready() -> void:
	visible = false
	claim_btn.pressed.connect(_claim)
	close_btn.pressed.connect(func(): visible = false)
	_load_daily()
	var today = _get_day()
	if today != last_claim_day:
		claimed_today = false
		_advance_streak(today)
		_refresh_ui()
		visible = true

func _get_day() -> int:
	var d = Time.get_datetime_dict_from_system()
	return d.year * 400 + d.month * 32 + d.day

func _advance_streak(today: int) -> void:
	if today == last_claim_day + 1:
		login_streak = mini(login_streak + 1, 9999)
	elif today > last_claim_day + 1:
		login_streak = 1
	else:
		login_streak = maxi(login_streak, 1)
	if login_streak > best_daily_streak:
		best_daily_streak = login_streak
	GameManager.best_daily_streak = best_daily_streak

func _get_streak_mult() -> float:
	return 1.0 + floor(login_streak / 7.0) * 0.5

func _day_slot() -> int:
	return (login_streak - 1) % 7

func _refresh_ui() -> void:
	for c in day_grid.get_children():
		c.queue_free()
	var slot = _day_slot()
	for i in 7:
		var r = reward_schedule[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(68, 54)
		btn.text = "Day %d\n%s" % [i + 1, r.label]
		btn.add_theme_font_size_override("font_size", 9)
		btn.disabled = true
		if i < slot or (i == slot and claimed_today):
			btn.add_theme_color_override("font_color", Color("#39FF14"))
		elif i == slot:
			btn.add_theme_color_override("font_color", Color("#FFD700"))
		else:
			btn.add_theme_color_override("font_color", Color("#444"))
		day_grid.add_child(btn)

	var today_reward = reward_schedule[slot]
	var mult = _get_streak_mult()
	var rt = ""
	match today_reward.type:
		"coins":
			var coins = int(today_reward.amount * mult)
			rt = "TODAY: +%d COINS" % coins
			if mult > 1.0:
				rt += "  (×%.1f streak bonus!)" % mult
		"token":
			rt = "TODAY: +%d FORGE TOKEN(S)" % today_reward.amount
		"both":
			var coins = int(today_reward.get("coins", 0) * mult)
			rt = "TODAY: +%d COINS + %d TOKEN  [WEEK BONUS!]" % [coins, today_reward.get("tokens", 1)]
	reward_label.text = rt
	streak_label.text = "Day %d streak  |  Best: %d" % [login_streak, best_daily_streak]
	claim_btn.text = "CLAIMED ✓" if claimed_today else "CLAIM"
	claim_btn.disabled = claimed_today

func _claim() -> void:
	if claimed_today:
		return
	var slot = _day_slot()
	var r = reward_schedule[slot]
	var mult = _get_streak_mult()
	match r.type:
		"coins":
			var coins = int(r.amount * mult)
			GameManager.add_coins(coins)
			GameManager.notification.emit("Daily Day %d: +%dc" % [login_streak, coins])
		"token":
			GameManager.forge_tokens += r.amount
			GameManager.notification.emit("Daily Day %d: +%d token(s)!" % [login_streak, r.amount])
		"both":
			var coins = int(r.get("coins", 0) * mult)
			var toks = r.get("tokens", 1)
			GameManager.add_coins(coins)
			GameManager.forge_tokens += toks
			GameManager.notification.emit("WEEKLY BONUS! +%dc +%d token(s)!" % [coins, toks])
	AudioManager.play_achievement()
	claimed_today = true
	last_claim_day = _get_day()
	_save_daily()
	_refresh_ui()
	get_tree().create_timer(3.0).timeout.connect(func(): visible = false)

func _load_daily() -> void:
	if not FileAccess.file_exists("user://daily.json"):
		return
	var f = FileAccess.open("user://daily.json", FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK:
		login_streak = json.data.get("streak", 0)
		best_daily_streak = json.data.get("best_streak", 0)
		last_claim_day = json.data.get("last_day", 0)

func _save_daily() -> void:
	var f = FileAccess.open("user://daily.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"streak": login_streak,
			"best_streak": best_daily_streak,
			"last_day": last_claim_day,
		}))

func show_panel() -> void:
	_load_daily()
	var today = _get_day()
	if today != last_claim_day:
		claimed_today = false
		_advance_streak(today)
	_refresh_ui()
	visible = true

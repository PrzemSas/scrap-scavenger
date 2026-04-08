extends PanelContainer

@onready var desc_label: Label = $VBox/Desc
@onready var progress_bar: ProgressBar = $VBox/Bar
@onready var reward_label: Label = $VBox/Reward

func _ready() -> void:
	ChallengeManager.challenge_updated.connect(_on_update)
	visible = false

func _on_update(ch: Dictionary) -> void:
	visible = true
	if ch.get("completed", false):
		desc_label.text = "✓ " + ch.get("desc", "")
		desc_label.add_theme_color_override("font_color", Color("#39FF14"))
		progress_bar.value = 100
		reward_label.text = "COMPLETED!"
		reward_label.add_theme_color_override("font_color", Color("#39FF14"))
	else:
		desc_label.text = ch.get("desc", "")
		desc_label.add_theme_color_override("font_color", Color("#ff6a00"))
		var progress = ChallengeManager.get_progress()
		var target = ChallengeManager.get_target()
		progress_bar.value = (float(progress) / target) * 100.0
		reward_label.text = "Reward: %dc | %d/%d" % [ch.get("reward", 0), progress, target]
		reward_label.add_theme_color_override("font_color", Color("#888"))

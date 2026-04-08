extends Control

@onready var title_label: Label = $VBox/Title
@onready var play_btn: Button = $VBox/PlayBtn
@onready var version_label: Label = $Version
@onready var save_info: Label = $SaveInfo

var _flicker_timer: float = 0.0

func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	version_label.text = "v0.6 PROTOTYPE // GORBAGANA CHAIN"
	# Show save info if exists
	if FileAccess.file_exists("user://savegame.json"):
		var file = FileAccess.open("user://savegame.json", FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var d = json.data
				var coins = d.get("coins", 0)
				var collected = d.get("total_collected", 0)
				var prestige = d.get("prestige_count", 0)
				var tokens = d.get("forge_tokens", 0)
				save_info.text = "SAVE FOUND: %d coins | %d collected | %d prestige | %d tokens" % [coins, collected, prestige, tokens]
				save_info.visible = true
				play_btn.text = "▶  CONTINUE"
			file.close()
	else:
		save_info.visible = false
		play_btn.text = "▶  NEW GAME"

func _process(delta: float) -> void:
	_flicker_timer += delta
	if fmod(_flicker_timer, 4.0) > 3.8:
		title_label.modulate.a = randf_range(0.7, 1.0)
	else:
		title_label.modulate.a = 1.0

func _on_play() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

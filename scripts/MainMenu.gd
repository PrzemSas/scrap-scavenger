extends Control

@onready var title_label: Label = $VBox/Title
@onready var sub_label: Label = $VBox/Subtitle
@onready var play_btn: Button = $VBox/PlayBtn
@onready var version_label: Label = $Version

var _flicker_timer: float = 0.0

func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	version_label.text = "v0.4 PROTOTYPE // GORBAGANA CHAIN"

func _process(delta: float) -> void:
	_flicker_timer += delta
	# Title flicker effect
	if fmod(_flicker_timer, 4.0) > 3.8:
		title_label.modulate.a = randf_range(0.7, 1.0)
	else:
		title_label.modulate.a = 1.0

func _on_play() -> void:
	AudioManager.play_click()
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

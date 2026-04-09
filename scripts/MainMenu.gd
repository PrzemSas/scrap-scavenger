extends Control
func _ready()->void:
	$VBox/PlayBtn.pressed.connect(func(): AudioManager.play_click(); get_tree().change_scene_to_file("res://scenes/main/Main.tscn"))
	$Version.text="v0.10 // GORBAGANA CHAIN"
	if FileAccess.file_exists("user://savegame.json"):
		$VBox/PlayBtn.text="▶  CONTINUE"
	else:
		$VBox/PlayBtn.text="▶  NEW GAME"

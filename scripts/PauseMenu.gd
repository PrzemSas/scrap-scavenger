extends Control

func _ready() -> void:
	visible = false
	$Panel/VBox/ResumeBtn.pressed.connect(_resume)
	$Panel/VBox/SaveBtn.pressed.connect(_save)
	$Panel/VBox/MenuBtn.pressed.connect(_to_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause() -> void:
	visible = not visible
	get_tree().paused = visible

func _resume() -> void:
	AudioManager.play_click()
	visible = false
	get_tree().paused = false

func _save() -> void:
	AudioManager.play_click()
	SaveManager.save_game()
	$Panel/VBox/SaveBtn.text = "✓ SAVED!"
	get_tree().create_timer(1.5).timeout.connect(func():
		$Panel/VBox/SaveBtn.text = "💾 SAVE GAME"
	)

func _to_menu() -> void:
	get_tree().paused = false
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")

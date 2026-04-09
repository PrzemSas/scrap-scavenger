extends Control
func _ready()->void:
	visible=false
	$Panel/VBox/ResumeBtn.pressed.connect(func(): visible=false; get_tree().paused=false)
	$Panel/VBox/SaveBtn.pressed.connect(func(): SaveManager.save_game())
	$Panel/VBox/MenuBtn.pressed.connect(func(): get_tree().paused=false; SaveManager.save_game(); get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn"))
func _unhandled_input(ev:InputEvent)->void:
	if ev.is_action_pressed("ui_cancel"): visible=not visible; get_tree().paused=visible

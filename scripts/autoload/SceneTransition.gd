extends CanvasLayer

# Prosty fade-to-black między scenami
# Użycie: SceneTransition.go("res://scenes/main/ForgeInterior.tscn")

var _overlay: ColorRect
var _fading: bool = false
var _target_scene: String = ""

func _ready() -> void:
	layer = 100
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

func go(scene_path: String) -> void:
	if _fading:
		return
	_fading = true
	_target_scene = scene_path
	_fade_in()

func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, 0.4)
	tween.tween_callback(_change_scene)

func _change_scene() -> void:
	SaveManager.save_game()
	get_tree().change_scene_to_file(_target_scene)
	await get_tree().process_frame
	await get_tree().process_frame
	_fade_out()

func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, 0.5)
	tween.tween_callback(func(): _fading = false)

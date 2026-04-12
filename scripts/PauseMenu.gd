extends Control

var _music: AudioStreamPlayer
var _slides: Array = [
	"res://assets/textures/pause_1.jpg",
	"res://assets/textures/pause_2.jpg",
	"res://assets/textures/pause_3.jpg",
	"res://assets/textures/pause_4.jpg",
	"res://assets/textures/pause_5.jpg",
	"res://assets/textures/pause_6.jpg",
	"res://assets/textures/forge_interior.jpg",
	"res://assets/textures/furnace_bg.jpg",
	"res://assets/textures/junkyard_worker.jpg",
	"res://assets/textures/industrial_hall.jpg",
	"res://assets/textures/br_02.jpg",
	"res://assets/textures/br_03.jpg",
	"res://assets/textures/br_04.jpg",
	"res://assets/textures/br_05.jpg",
	"res://assets/textures/br_07.jpg",
	"res://assets/textures/br_09.jpg",
	"res://assets/textures/br_10.jpg",
	"res://assets/textures/br_12.jpg",
	"res://assets/textures/br_13.jpg",
	"res://assets/textures/br_17.jpg",
	"res://assets/textures/mot_01.jpg",
	"res://assets/textures/mot_02.jpg",
	"res://assets/textures/mot_03.jpg",
	"res://assets/textures/mot_04.jpg",
	"res://assets/textures/mot_05.jpg",
	"res://assets/textures/mot_06.jpg",
	"res://assets/textures/mot_07.jpg",
	"res://assets/textures/mot_08.jpg",
	"res://assets/textures/mot_09.jpg",
	"res://assets/textures/mot_10.jpg",
	"res://assets/textures/mot_11.jpg",
	"res://assets/textures/mot_12.jpg",
	"res://assets/textures/gt_01.jpg",
	"res://assets/textures/gt_02.jpg",
	"res://assets/textures/gt_03.jpg",
	"res://assets/textures/gt_04.jpg",
	"res://assets/textures/gt_05.jpg",
	"res://assets/textures/gt_06.jpg",
	"res://assets/textures/gt_07.jpg",
	"res://assets/textures/gt_08.jpg",
	"res://assets/textures/gt_09.jpg",
	"res://assets/textures/gt_10.jpg",
	"res://assets/textures/gt_11.jpg",
	"res://assets/textures/gt_12.jpg",
	"res://assets/textures/gt_13.jpg",
	"res://assets/textures/gt_14.jpg",
]
var _idx: int = 0
var _fade_t: float = 0.0
var _fade_dur: float = 1.5
var _hold_dur: float = 4.0
var _hold_t: float = 0.0
var _fading: bool = false
var _slide_a: TextureRect
var _slide_b: TextureRect

func _ready() -> void:
	visible = false
	_slide_a = $SlideA
	_slide_b = $SlideB
	_slide_a.texture = load(_slides[0])

	_music = AudioStreamPlayer.new()
	_music.stream = load("res://assets/audio/pause_music.mp3")
	_music.volume_db = -6.0
	add_child(_music)
	_music.finished.connect(func(): if visible: _music.play())

	$Panel/VBox/ResumeBtn.pressed.connect(_resume)
	$Panel/VBox/SaveBtn.pressed.connect(func(): SaveManager.save_game())
	$Panel/VBox/MenuBtn.pressed.connect(func():
		get_tree().paused = false
		SaveManager.save_game()
		get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn"))

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		visible = not visible
		get_tree().paused = visible
		if visible:
			_music.play()
			_hold_t = 0.0
			_fading = false
		else:
			_music.stop()

func _resume() -> void:
	visible = false
	get_tree().paused = false
	_music.stop()

func _process(delta: float) -> void:
	if not visible: return
	if _fading:
		_fade_t += delta
		var p: float = clampf(_fade_t / _fade_dur, 0.0, 1.0)
		_slide_b.modulate.a = p
		_slide_a.modulate.a = 1.0 - p
		if p >= 1.0:
			_slide_a.texture = _slide_b.texture
			_slide_a.modulate.a = 1.0
			_slide_b.modulate.a = 0.0
			_fading = false
			_hold_t = 0.0
	else:
		_hold_t += delta
		if _hold_t >= _hold_dur:
			_idx = (_idx + 1) % _slides.size()
			_slide_b.texture = load(_slides[_idx])
			_fade_t = 0.0
			_fading = true

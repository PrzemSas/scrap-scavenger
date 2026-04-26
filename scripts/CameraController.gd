extends Camera3D

const PANEL_TO_NODE: Dictionary = {
	"furnace": "Furnace3D",
	"sort":    "Table3D",
	"shop":    "ShopPoint",
	"sell":    "SellPoint",
}

@export var start_in_fp: bool = false

var _zoom: float = 14.0
var _target: Node3D = null
var _shake_amount: float = 0.0
var _shake_freq:  float = 5.0
var _shake_t:     float = 0.0

var _fp_mode: bool = false
var _focus_target: Node3D = null
var _user_override: bool = false
var _fp_look_dir: Vector3 = Vector3.FORWARD  # stały kierunek patrzenia (bez celu)

var _orig_projection: Camera3D.ProjectionType = PROJECTION_PERSPECTIVE
var _orig_fov: float = 50.0
var _orig_size: float = 22.0

var _player_meshes: Array[MeshInstance3D] = []

func _ready() -> void:
	await get_tree().process_frame
	_target = get_tree().current_scene.get_node_or_null("Player")
	_orig_projection = projection
	_orig_fov        = fov
	_orig_size       = size
	if is_instance_valid(_target):
		for child in _target.get_children():
			if child is MeshInstance3D:
				_player_meshes.append(child)
	GameManager.proximity_entered.connect(_on_proximity_entered)
	GameManager.proximity_exited.connect(_on_proximity_exited)
	if start_in_fp:
		_enter_fp()

func shake(amount: float, freq: float = 5.0) -> void:
	_shake_amount = amount
	_shake_freq   = freq
	_shake_t      = 0.0

func _on_proximity_entered(panel_id: String) -> void:
	if not PANEL_TO_NODE.has(panel_id): return
	var node := get_tree().current_scene.get_node_or_null(PANEL_TO_NODE[panel_id])
	if not is_instance_valid(node): return
	_focus_target = node
	if not _user_override:
		_enter_fp()

func _on_proximity_exited(panel_id: String) -> void:
	if not PANEL_TO_NODE.has(panel_id): return
	_focus_target = null
	_user_override = false
	_exit_fp()

func _enter_fp() -> void:
	if not is_instance_valid(_target): return
	_fp_mode = true
	GameManager.fp_mode = true
	projection = PROJECTION_PERSPECTIVE
	fov = 75.0
	if is_instance_valid(_focus_target):
		var d := _focus_target.global_position - _target.global_position
		d.y = 0.0
		_fp_look_dir = d.normalized() if d.length() > 0.1 else Vector3.FORWARD
	else:
		var fwd := -_target.global_transform.basis.z
		fwd.y = 0.0
		_fp_look_dir = fwd.normalized() if fwd.length() > 0.01 else Vector3.FORWARD
	for m in _player_meshes:
		m.visible = false

func _exit_fp() -> void:
	_fp_mode = false
	GameManager.fp_mode = false
	projection = _orig_projection
	fov = _orig_fov
	size = _orig_size
	for m in _player_meshes:
		m.visible = true

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		if ev.keycode == KEY_C:
			if _fp_mode:
				_user_override = true
				_exit_fp()
			else:
				_user_override = false
				_enter_fp()
			return
	if not _fp_mode and ev is InputEventMouseButton:
		if   ev.button_index == MOUSE_BUTTON_WHEEL_UP:   _zoom = max(_zoom - 1.0, 7.0)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN: _zoom = min(_zoom + 1.0, 24.0)

func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = get_tree().current_scene.get_node_or_null("Player")
		return

	if _fp_mode:
		if is_instance_valid(_focus_target):
			var d := _focus_target.global_position - _target.global_position
			d.y = 0.0
			_fp_look_dir = d.normalized() if d.length() > 0.1 else _fp_look_dir
			var eye := _target.global_position + Vector3(0, 1.6, 0)
			global_position = eye
			look_at(_focus_target.global_position + Vector3(0, 1.1, 0))
		else:
			# śledź obrót gracza — kamera = oczy gracza
			var fwd := -_target.global_transform.basis.z
			fwd.y = 0.0
			if fwd.length() > 0.01:
				_fp_look_dir = fwd.normalized()
			var eye := _target.global_position + Vector3(0, 1.6, 0)
			global_position = eye
			look_at(eye + _fp_look_dir * 5.0)
		return

	var look_at_pos := _target.global_position + Vector3(0, 0.8, 0)
	var cam_target  := _target.global_position + Vector3(0, _zoom, _zoom * 0.75)
	global_position  = global_position.lerp(cam_target, delta * 7.0)
	look_at(look_at_pos)
	if _shake_amount > 0.0:
		_shake_t += delta * _shake_freq
		var ox: float = sin(_shake_t * 2.3) * _shake_amount
		var oy: float = cos(_shake_t * 3.7) * _shake_amount * 0.4
		global_position += Vector3(ox, oy, 0.0)
		_shake_amount = move_toward(_shake_amount, 0.0, delta * 5.0)

extends CharacterBody3D

const SPEED        := 5.5
const SPRINT_SPEED := 9.0
const GRAVITY      := 22.0

# Base positions (muszą zgadzać się z .tscn)
const _BY  := 0.60   # body Y
const _HY  := 1.42   # head Y
const _HTY := 1.52   # helmet top Y
const _HFY := 1.38   # helmet front Y
const _VY  := 1.39   # visor Y
const _GLX := -0.36  # glove L X
const _GRX :=  0.36  # glove R X
const _GY  :=  0.50  # gloves Y
const _LLX := -0.13  # leg L X
const _LRX :=  0.13  # leg R X
const _LY  :=  0.19  # legs Y (center)
const _BLX := -0.13  # boot L X
const _BRX :=  0.13  # boot R X
const _BOOTY :=  0.04  # boots Y
const _BOOTZ :=  0.03  # boots Z offset

@onready var _body:         MeshInstance3D = $Body
@onready var _head:         MeshInstance3D = $Head
@onready var _helmet_top:   MeshInstance3D = $HelmetTop
@onready var _helmet_front: MeshInstance3D = $HelmetFront
@onready var _visor:        MeshInstance3D = $Visor
@onready var _glove_l:      MeshInstance3D = $GloveL
@onready var _glove_r:      MeshInstance3D = $GloveR
@onready var _leg_l:        MeshInstance3D = $LegL
@onready var _leg_r:        MeshInstance3D = $LegR
@onready var _boot_l:       MeshInstance3D = $BootL
@onready var _boot_r:       MeshInstance3D = $BootR

var _footstep_t:  float = 0.0
var _walk_t:      float = 0.0
var _walk_blend:  float = 0.0
var _is_moving:   bool  = false
var _is_sprinting:bool  = false
var _land_squash: float = 0.0
var _was_on_floor:bool  = true

func _ready() -> void:
	add_to_group("player")
	if SceneTransition.spawn_override != Vector3.ZERO:
		global_position = SceneTransition.spawn_override
		SceneTransition.spawn_override = Vector3.ZERO

func _physics_process(delta: float) -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	var input_dir := Vector2.ZERO
	if Input.is_action_pressed("ui_left"):  input_dir.x -= 1
	if Input.is_action_pressed("ui_right"): input_dir.x += 1
	if Input.is_action_pressed("ui_up"):    input_dir.y -= 1
	if Input.is_action_pressed("ui_down"):  input_dir.y += 1
	_is_sprinting = Input.is_key_pressed(KEY_SHIFT)
	var speed := SPRINT_SPEED if _is_sprinting else SPEED
	var dir := Vector3.ZERO
	if GameManager.fp_mode:
		# lewo/prawo = obrót gracza, góra/dół = ruch w przód/tył bez zmiany obrotu
		if input_dir.x != 0.0:
			rotation.y -= input_dir.x * delta * 2.5
		if input_dir.y != 0.0:
			var pf := -global_basis.z; pf.y = 0.0
			if pf.length_squared() > 0.001:
				dir = pf.normalized() * (-input_dir.y)
	elif input_dir != Vector2.ZERO:
		if cam:
			var cf := -cam.global_basis.z; cf.y = 0
			var cr :=  cam.global_basis.x; cr.y = 0
			if cf.length_squared() > 0.001: cf = cf.normalized()
			if cr.length_squared() > 0.001: cr = cr.normalized()
			dir = (cf * (-input_dir.y) + cr * input_dir.x).normalized()
		else:
			dir = Vector3(input_dir.x, 0, input_dir.y).normalized()
	_is_moving = dir.length_squared() > 0
	if _is_moving and not GameManager.fp_mode:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.18)
		_footstep_t += delta
		var step_interval := 0.38 * (SPEED / speed)
		if _footstep_t >= step_interval:
			_footstep_t = 0.0
			if AudioManager.has_method("play_footstep"):
				AudioManager.play_footstep()
	else:
		_footstep_t = 0.0
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if not is_on_floor(): velocity.y -= GRAVITY * delta
	else:                 velocity.y  = 0.0
	move_and_slide()
	# Wykrycie lądowania
	if is_on_floor() and not _was_on_floor:
		_land_squash = 1.0
	_was_on_floor = is_on_floor()

func _process(delta: float) -> void:
	_animate(delta)

func _animate(delta: float) -> void:
	var walk_freq := 2.4 if _is_sprinting else 1.5
	_walk_blend = move_toward(_walk_blend, 1.0 if _is_moving else 0.0, delta * 6.0)
	if _walk_blend > 0.001:
		_walk_t += delta * walk_freq * _walk_blend

	var sc:  float = sin(_walk_t * TAU)
	var sc2: float = abs(sc)
	var b:   float = _walk_blend

	# Amplitudy
	var bob_amp:  float = 0.045 if _is_sprinting else 0.028
	var arm_amp:  float = 0.11  if _is_sprinting else 0.075
	var leg_amp:  float = 0.08  if _is_sprinting else 0.055
	var tilt_amp: float = 0.12  if _is_sprinting else 0.0

	# Landing squash (zanika w ~0.25s)
	if _land_squash > 0.0:
		_land_squash = move_toward(_land_squash, 0.0, delta * 9.0)
	var sq_y:  float = 1.0 - _land_squash * 0.14
	var sq_xz: float = 1.0 + _land_squash * 0.07
	_body.scale = Vector3(sq_xz, sq_y, sq_xz)

	# --- Ciało ---
	var body_bob: float = sc2 * bob_amp * b
	_body.position.y      = _BY  + body_bob
	_body.rotation.x      = -tilt_amp * b

	# --- Głowa + hełm (lekko za ciałem) ---
	var hbob: float = body_bob * 0.75
	_head.position.y         = _HY  + hbob
	_helmet_top.position.y   = _HTY + hbob
	_helmet_front.position.y = _HFY + hbob
	_visor.position.y        = _VY  + hbob

	# --- Ręce — przeciwne fazy ---
	var glove_bob: float = body_bob * 0.5
	_glove_l.position = Vector3(_GLX, _GY + glove_bob,  sc * arm_amp * b)
	_glove_r.position = Vector3(_GRX, _GY + glove_bob, -sc * arm_amp * b)

	# --- Nogi — Z swing (przeciwny do rąk) ---
	_leg_l.position  = Vector3(_LLX, _LY,    -sc * leg_amp * b)
	_leg_r.position  = Vector3(_LRX, _LY,     sc * leg_amp * b)
	_boot_l.position = Vector3(_BLX, _BOOTY, -sc * leg_amp * b * 1.2 + _BOOTZ)
	_boot_r.position = Vector3(_BRX, _BOOTY,  sc * leg_amp * b * 1.2 + _BOOTZ)

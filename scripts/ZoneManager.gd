extends Node3D

var _env: Environment
var _sun: DirectionalLight3D
var _forge_zone: Area3D
var _camera: Camera3D
var _in_forge: bool = false
var _blend: float = 0.0

const JY_AMB_COL  := Color(0.32, 0.18, 0.08)
const JY_AMB_E    := 0.65
const JY_FOG_COL  := Color(0.30, 0.18, 0.07)
const JY_FOG_D    := 0.012
const JY_GLOW     := 0.95
const JY_SUN      := 0.80

const FG_AMB_COL  := Color(0.32, 0.14, 0.04)
const FG_AMB_E    := 1.2
const FG_FOG_COL  := Color(0.22, 0.08, 0.01)
const FG_FOG_D    := 0.030
const FG_GLOW     := 1.1
const FG_SUN      := 0.03

func _ready() -> void:
	var we := get_parent().get_node_or_null("WorldEnvironment")
	if we:
		_env = we.environment
	_sun = get_parent().get_node_or_null("SunLight")
	await get_tree().process_frame
	_forge_zone = get_parent().get_node_or_null("ForgeStructure/ForgeZone")
	if _forge_zone:
		_forge_zone.body_entered.connect(_on_enter)
		_forge_zone.body_exited.connect(_on_exit)
	_camera = get_parent().get_node_or_null("Camera3D")
	AudioManager.play_zone("junkyard", -22.0)

func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"):
		_in_forge = true
		if _camera:
			_camera.enter_zone_fp()
		AudioManager.play_zone("forge", -20.0)

func _on_exit(body: Node3D) -> void:
	if body.is_in_group("player"):
		_in_forge = false
		if _camera:
			_camera.exit_zone_fp()
		AudioManager.play_zone("junkyard", -22.0)

func _process(delta: float) -> void:
	if not _env:
		return
	var target := 1.0 if _in_forge else 0.0
	_blend = move_toward(_blend, target, delta * 1.4)
	_env.ambient_light_color = JY_AMB_COL.lerp(FG_AMB_COL, _blend)
	_env.ambient_light_energy = lerpf(JY_AMB_E, FG_AMB_E, _blend)
	_env.fog_light_color = JY_FOG_COL.lerp(FG_FOG_COL, _blend)
	# fog_density zarządzane przez DayNightCycle — nie dotykamy
	_env.glow_intensity = lerpf(JY_GLOW, FG_GLOW, _blend)
	if _sun:
		_sun.light_energy = lerpf(JY_SUN, FG_SUN, _blend)

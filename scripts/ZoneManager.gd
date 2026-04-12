extends Node3D

var _env: Environment
var _sun: DirectionalLight3D
var _forge_zone: Area3D
var _in_forge: bool = false
var _blend: float = 0.0

# Nodes to hide when inside the forge (roof + south wall block the isometric camera)
var _hide_when_inside: Array[Node3D] = []

const JY_AMB_COL  := Color(0.12, 0.08, 0.04)
const JY_AMB_E    := 0.4
const JY_FOG_COL  := Color(0.10, 0.06, 0.02)
const JY_FOG_D    := 0.010
const JY_GLOW     := 0.4
const JY_SUN      := 0.7

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

	# Collect nodes to hide when inside
	var fs := get_parent().get_node_or_null("ForgeStructure")
	if fs:
		for node_name in ["RoofWest", "RoofEast", "WallS"]:
			var n: Node3D = fs.get_node_or_null(node_name)
			if n:
				_hide_when_inside.append(n)

	AudioManager.play_music("junkyard", -22.0)

func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"):
		_in_forge = true
		for n in _hide_when_inside:
			n.visible = false
		AudioManager.play_music("forge", -20.0)

func _on_exit(body: Node3D) -> void:
	if body.is_in_group("player"):
		_in_forge = false
		for n in _hide_when_inside:
			n.visible = true
		AudioManager.play_music("junkyard", -22.0)

func _process(delta: float) -> void:
	if not _env:
		return
	var target := 1.0 if _in_forge else 0.0
	_blend = move_toward(_blend, target, delta * 1.4)
	_env.ambient_light_color = JY_AMB_COL.lerp(FG_AMB_COL, _blend)
	_env.ambient_light_energy = lerpf(JY_AMB_E, FG_AMB_E, _blend)
	_env.fog_light_color = JY_FOG_COL.lerp(FG_FOG_COL, _blend)
	_env.fog_density = lerpf(JY_FOG_D, FG_FOG_D, _blend)
	_env.glow_intensity = lerpf(JY_GLOW, FG_GLOW, _blend)
	if _sun:
		_sun.light_energy = lerpf(JY_SUN, FG_SUN, _blend)

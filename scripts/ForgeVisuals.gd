extends Node

@onready var _env_node: WorldEnvironment = get_parent().get_node("WorldEnvironment")
@onready var _main_light: OmniLight3D = get_parent().get_node("MainForgeLight")
@onready var _embers: CPUParticles3D = get_parent().get_node("EmberDrift")

const STAGE_FOG:    Array = [0.06, 0.04, 0.022, 0.012]
const STAGE_AMBIENT: Array = [0.4,  0.7,  1.0,   1.3]
const STAGE_GLOW:   Array = [0.8,  1.1,  1.7,   2.3]
const STAGE_MAIN:   Array = [2.5,  3.2,  4.5,   5.5]
const STAGE_EMBERS: Array = [30,   65,   110,   160]

var _stage_groups: Array[Node3D] = []

func _ready() -> void:
	_build_visuals()
	GameManager.forge_stage_changed.connect(_on_stage_changed)
	_apply_stage(GameManager.forge_stage, false)

func _build_visuals() -> void:
	_stage_groups.append(_build_stage1())
	_stage_groups.append(_build_stage2())
	_stage_groups.append(_build_stage3())
	for g in _stage_groups:
		g.visible = false
		get_parent().add_child(g)

func _build_stage1() -> Node3D:
	var g := Node3D.new()
	g.name = "Stage1Visuals"
	_add_lantern(g, Vector3(-7, 3.5, -14.4), Color(1.0, 0.72, 0.22), 1.8, 9.0)
	_add_lantern(g, Vector3( 7, 3.5, -14.4), Color(1.0, 0.72, 0.22), 1.8, 9.0)
	return g

func _build_stage2() -> Node3D:
	var g := Node3D.new()
	g.name = "Stage2Visuals"
	_add_lantern(g, Vector3(-14.4, 3.5, -4), Color(1.0, 0.62, 0.14), 2.2, 10.0)
	_add_lantern(g, Vector3( 14.4, 3.5, -4), Color(1.0, 0.62, 0.14), 2.2, 10.0)
	_add_lantern(g, Vector3(0, 1.8, -1),     Color(0.18, 1.0, 0.48),  1.4,  7.0)
	return g

func _build_stage3() -> Node3D:
	var g := Node3D.new()
	g.name = "Stage3Visuals"

	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 2.2, -13)
	glow.light_color = Color(0.28, 0.55, 1.0)
	glow.light_energy = 4.0
	glow.omni_range = 13.0
	g.add_child(glow)

	var portal := CPUParticles3D.new()
	portal.position = Vector3(0, 1.2, -13)
	portal.emitting = true
	portal.amount = 70
	portal.lifetime = 3.2
	portal.emission_shape = 1
	portal.emission_sphere_radius = 1.6
	portal.direction = Vector3(0, 1, 0)
	portal.gravity = Vector3(0, 0.08, 0)
	portal.initial_velocity_min = 0.2
	portal.initial_velocity_max = 0.7
	portal.scale_amount_min = 0.03
	portal.scale_amount_max = 0.09
	portal.color = Color(0.28, 0.55, 1.0, 0.35)
	g.add_child(portal)

	return g

func _add_lantern(parent: Node3D, pos: Vector3, color: Color, energy: float, range: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range
	parent.add_child(light)

func _on_stage_changed(stage: int) -> void:
	_burst_embers()
	_apply_stage(stage, true)

func _apply_stage(stage: int, animate: bool) -> void:
	var env: Environment = _env_node.environment
	var dur: float = 2.0 if animate else 0.0

	if animate:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(env, "fog_density",         STAGE_FOG[stage],    dur)
		tw.tween_property(env, "ambient_light_energy", STAGE_AMBIENT[stage], dur)
		tw.tween_property(env, "glow_intensity",       STAGE_GLOW[stage],   dur)
		tw.tween_property(_main_light, "light_energy", STAGE_MAIN[stage],   dur)
	else:
		env.fog_density          = STAGE_FOG[stage]
		env.ambient_light_energy = STAGE_AMBIENT[stage]
		env.glow_intensity       = STAGE_GLOW[stage]
		_main_light.light_energy = STAGE_MAIN[stage]

	_embers.amount = STAGE_EMBERS[stage]

	for i in _stage_groups.size():
		_stage_groups[i].visible = (i < stage)

func _burst_embers() -> void:
	var prev := _embers.amount
	_embers.amount = 300
	await get_tree().create_timer(0.6).timeout
	_embers.amount = STAGE_EMBERS[GameManager.forge_stage]

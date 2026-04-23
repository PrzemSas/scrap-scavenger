extends Node

@onready var _pit_nw: OmniLight3D = get_parent().get_node("FirePit_NW")
@onready var _pit_ne: OmniLight3D = get_parent().get_node("FirePit_NE")
@onready var _pit_sw: OmniLight3D = get_parent().get_node("FirePit_SW")
@onready var _pit_se: OmniLight3D = get_parent().get_node("FirePit_SE")

const PIT_POSITIONS := [
	Vector3(-10, 0.35, -10),
	Vector3( 10, 0.35, -10),
	Vector3(-10, 0.35,  5),
	Vector3( 10, 0.35,  5),
]
const CENTRAL_POS   := Vector3(0, 0.35, -4)

# energy per forge stage (mirrors ForgeVisuals STAGE_PITS)
const STAGE_PITS: Array = [1.2, 2.0, 3.0, 3.8]

# per-pit flicker parameters (different phase/freq so they don't sync)
const FLICKER_FREQ := [7.3, 8.1, 6.8, 9.2]
const FLICKER_PH   := [0.0, 1.7, 3.3, 5.1]

var _pits:          Array
var _pit_flames:    Array[CPUParticles3D]
var _central_outer: CPUParticles3D
var _central_inner: CPUParticles3D

var _base_energy:   float = 1.2
var _target_energy: float = 1.2
var _trans_t:       float = 1.0

func _ready() -> void:
	_pits = [_pit_nw, _pit_ne, _pit_sw, _pit_se]

	var stage: int = GameManager.forge_stage
	_base_energy   = STAGE_PITS[stage]
	_target_energy = _base_energy

	for pos in PIT_POSITIONS:
		var f := _make_pit_flame(pos, stage)
		_pit_flames.append(f)
		get_parent().add_child(f)

	_central_outer = _make_central_outer(stage)
	_central_inner = _make_central_inner(stage)
	get_parent().add_child(_central_outer)
	get_parent().add_child(_central_inner)

	GameManager.forge_stage_changed.connect(_on_stage_changed)

func _process(_delta: float) -> void:
	_trans_t = minf(_trans_t + _delta / 2.0, 1.0)
	var energy := lerpf(_base_energy, _target_energy, _trans_t)
	var t := Time.get_ticks_msec() * 0.001
	for i in _pits.size():
		var f := 1.0 \
			+ 0.18 * sin(t * FLICKER_FREQ[i] + FLICKER_PH[i]) \
			+ 0.07 * sin(t * FLICKER_FREQ[i] * 2.7 + FLICKER_PH[i] + 0.9)
		_pits[i].light_energy = energy * f

func _on_stage_changed(stage: int) -> void:
	_base_energy   = lerpf(_base_energy, _target_energy, _trans_t)
	_target_energy = STAGE_PITS[stage]
	_trans_t       = 0.0

	var pit_amt  := 30 + stage * 15
	var cent_amt := 70 + stage * 25
	for f in _pit_flames:
		f.amount = pit_amt
	_central_outer.amount = cent_amt
	_central_inner.amount = ceili(cent_amt * 0.4)

# ── builders ─────────────────────────────────────────────────────────────────

func _make_pit_flame(pos: Vector3, stage: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position          = pos
	p.emitting          = true
	p.amount            = 30 + stage * 15
	p.lifetime          = 1.3
	p.emission_shape    = 1   # SPHERE
	p.emission_sphere_radius = 0.28
	p.direction         = Vector3(0, 1, 0)
	p.spread            = 20.0
	p.gravity           = Vector3(0, -0.10, 0)
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.0
	p.scale_amount_min  = 0.10
	p.scale_amount_max  = 0.26
	p.color             = Color(1.0, 0.50, 0.05, 0.9)
	p.color_ramp        = _pit_gradient()
	return p

func _make_central_outer(stage: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position          = CENTRAL_POS
	p.emitting          = true
	p.amount            = 70 + stage * 25
	p.lifetime          = 2.2
	p.emission_shape    = 1
	p.emission_sphere_radius = 0.85
	p.direction         = Vector3(0, 1, 0)
	p.spread            = 28.0
	p.gravity           = Vector3(0, -0.06, 0)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.5
	p.scale_amount_min  = 0.20
	p.scale_amount_max  = 0.55
	p.color             = Color(1.0, 0.55, 0.06, 0.92)
	p.color_ramp        = _outer_gradient()
	return p

func _make_central_inner(stage: int) -> CPUParticles3D:
	# bright white-yellow core — runs on top of outer flame
	var p := CPUParticles3D.new()
	p.position          = CENTRAL_POS
	p.emitting          = true
	p.amount            = ceili((70 + stage * 25) * 0.4)
	p.lifetime          = 1.2
	p.emission_shape    = 1
	p.emission_sphere_radius = 0.30
	p.direction         = Vector3(0, 1, 0)
	p.spread            = 12.0
	p.gravity           = Vector3(0, -0.04, 0)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 6.5
	p.scale_amount_min  = 0.09
	p.scale_amount_max  = 0.20
	p.color             = Color(1.0, 0.97, 0.55, 1.0)
	p.color_ramp        = _inner_gradient()
	return p

# ── gradients ─────────────────────────────────────────────────────────────────

func _pit_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors  = PackedColorArray([
		Color(1.0, 0.88, 0.18, 0.95),
		Color(1.0, 0.32, 0.03, 0.65),
		Color(0.18, 0.0,  0.0,  0.0),
	])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	return g

func _outer_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors  = PackedColorArray([
		Color(1.0, 0.80, 0.12, 0.95),
		Color(1.0, 0.38, 0.03, 0.72),
		Color(0.25, 0.0,  0.0,  0.0),
	])
	g.offsets = PackedFloat32Array([0.0, 0.50, 1.0])
	return g

func _inner_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors  = PackedColorArray([
		Color(1.0, 1.0,  0.70, 1.0),
		Color(1.0, 0.75, 0.15, 0.80),
		Color(1.0, 0.35, 0.02, 0.0),
	])
	g.offsets = PackedFloat32Array([0.0, 0.40, 1.0])
	return g

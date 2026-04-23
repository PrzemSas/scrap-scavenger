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
# flame erupts from just inside the forge opening
const CENTRAL_POS   := Vector3(0, 0.55, -5.1)

# energy per forge stage (mirrors ForgeVisuals.STAGE_PITS, now owned here)
const STAGE_PITS: Array = [1.2, 2.0, 3.0, 3.8]

# per-pit flicker params — different phase & freq so they never sync
const FLICKER_FREQ := [7.3, 8.1, 6.8, 9.2]
const FLICKER_PH   := [0.0, 1.7, 3.3, 5.1]

var _pits:          Array
var _pit_flames:    Array[CPUParticles3D]
var _pit_sparks:    Array[CPUParticles3D]
var _pit_smokes:    Array[CPUParticles3D]
var _central_outer: CPUParticles3D
var _central_inner: CPUParticles3D
var _central_spark: CPUParticles3D
var _central_smoke: CPUParticles3D

var _base_energy:  float = 1.2
var _target_energy: float = 1.2
var _trans_t:       float = 1.0

func _ready() -> void:
	_pits = [_pit_nw, _pit_ne, _pit_sw, _pit_se]
	var stage := GameManager.forge_stage
	_base_energy   = STAGE_PITS[stage]
	_target_energy = _base_energy

	for pos in PIT_POSITIONS:
		var flame := _make_pit_flame(pos, stage)
		var spark := _make_sparks(pos + Vector3(0, 0.25, 0), 18, false)
		var smoke := _make_smoke(pos + Vector3(0, 1.25, 0), 8, false)
		_pit_flames.append(flame)
		_pit_sparks.append(spark)
		_pit_smokes.append(smoke)
		get_parent().add_child(flame)
		get_parent().add_child(spark)
		get_parent().add_child(smoke)

	_central_outer = _make_central_outer(stage)
	_central_inner = _make_central_inner(stage)
	_central_spark = _make_sparks(CENTRAL_POS + Vector3(0, 0.3, 0), 40, true)
	_central_smoke = _make_smoke(CENTRAL_POS + Vector3(0, 2.2, 0), 22, true)
	get_parent().add_child(_central_outer)
	get_parent().add_child(_central_inner)
	get_parent().add_child(_central_spark)
	get_parent().add_child(_central_smoke)

	GameManager.forge_stage_changed.connect(_on_stage_changed)

func _process(delta: float) -> void:
	_trans_t = minf(_trans_t + delta / 2.0, 1.0)
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

	var pit_flame_amt := 30 + stage * 15
	var pit_spark_amt := 12 + stage * 8
	var cent_amt      := 70 + stage * 25
	for i in _pit_flames.size():
		_pit_flames[i].amount = pit_flame_amt
		_pit_sparks[i].amount = pit_spark_amt
	_central_outer.amount = cent_amt
	_central_inner.amount = ceili(cent_amt * 0.4)
	_central_spark.amount = 30 + stage * 15
	_central_smoke.amount = 18 + stage * 5

# ── flame builders ────────────────────────────────────────────────────────────

func _make_pit_flame(pos: Vector3, stage: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position               = pos
	p.emitting               = true
	p.amount                 = 30 + stage * 15
	p.lifetime               = 1.3
	p.emission_shape         = 1   # SPHERE
	p.emission_sphere_radius = 0.28
	p.direction              = Vector3(0, 1, 0)
	p.spread                 = 20.0
	p.gravity                = Vector3(0, -0.10, 0)
	p.initial_velocity_min   = 1.5
	p.initial_velocity_max   = 3.0
	p.scale_amount_min       = 0.10
	p.scale_amount_max       = 0.26
	p.color                  = Color(1.0, 1.0, 1.0, 1.0)
	p.color_ramp             = _pit_gradient()
	return p

func _make_central_outer(stage: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position               = CENTRAL_POS
	p.emitting               = true
	p.amount                 = 70 + stage * 25
	p.lifetime               = 2.2
	p.emission_shape         = 1
	p.emission_sphere_radius = 0.80
	p.direction              = Vector3(0, 1, 0)
	p.spread                 = 26.0
	p.gravity                = Vector3(0, -0.06, 0)
	p.initial_velocity_min   = 2.0
	p.initial_velocity_max   = 5.5
	p.scale_amount_min       = 0.20
	p.scale_amount_max       = 0.55
	p.color                  = Color(1.0, 1.0, 1.0, 1.0)
	p.color_ramp             = _outer_gradient()
	return p

func _make_central_inner(stage: int) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position               = CENTRAL_POS
	p.emitting               = true
	p.amount                 = ceili((70 + stage * 25) * 0.4)
	p.lifetime               = 1.2
	p.emission_shape         = 1
	p.emission_sphere_radius = 0.28
	p.direction              = Vector3(0, 1, 0)
	p.spread                 = 11.0
	p.gravity                = Vector3(0, -0.04, 0)
	p.initial_velocity_min   = 3.2
	p.initial_velocity_max   = 6.5
	p.scale_amount_min       = 0.09
	p.scale_amount_max       = 0.20
	p.color                  = Color(1.0, 1.0, 1.0, 1.0)
	p.color_ramp             = _inner_gradient()
	return p

# ── spark & smoke builders ────────────────────────────────────────────────────

func _make_sparks(pos: Vector3, amount: int, is_central: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position               = pos
	p.emitting               = true
	p.amount                 = amount
	p.lifetime               = 1.6 if is_central else 1.2
	p.emission_shape         = 1
	p.emission_sphere_radius = 0.18 if is_central else 0.10
	p.direction              = Vector3(0, 1, 0)
	p.spread                 = 65.0
	p.gravity                = Vector3(0, -7.5, 0)
	p.initial_velocity_min   = 3.5 if is_central else 2.5
	p.initial_velocity_max   = 9.0 if is_central else 5.5
	p.scale_amount_min       = 0.012
	p.scale_amount_max       = 0.030
	p.color                  = Color(1.0, 1.0, 1.0, 1.0)
	p.color_ramp             = _spark_gradient()
	return p

func _make_smoke(pos: Vector3, amount: int, is_central: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position              = pos
	p.emitting              = true
	p.amount                = amount
	p.lifetime              = 6.0 if is_central else 4.5
	p.emission_shape        = 3   # BOX
	p.emission_box_extents  = Vector3(0.6, 0.2, 0.6) if is_central else Vector3(0.35, 0.1, 0.35)
	p.direction             = Vector3(0, 1, 0)
	p.spread                = 38.0
	p.gravity               = Vector3(0.015, 0.03, 0)
	p.initial_velocity_min  = 0.12
	p.initial_velocity_max  = 0.50
	p.scale_amount_min      = 0.35 if is_central else 0.22
	p.scale_amount_max      = 0.85 if is_central else 0.52
	p.color                 = Color(1.0, 1.0, 1.0, 1.0)
	p.color_ramp            = _smoke_gradient()
	return p

# ── gradients ─────────────────────────────────────────────────────────────────

func _pit_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors  = PackedColorArray([
		Color(1.0, 0.90, 0.20, 0.95),
		Color(1.0, 0.35, 0.03, 0.65),
		Color(0.18, 0.0,  0.0,  0.0),
	])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	return g

func _outer_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors  = PackedColorArray([
		Color(1.0, 0.80, 0.14, 0.95),
		Color(1.0, 0.40, 0.04, 0.70),
		Color(0.22, 0.0,  0.0,  0.0),
	])
	g.offsets = PackedFloat32Array([0.0, 0.50, 1.0])
	return g

func _inner_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors  = PackedColorArray([
		Color(1.0, 1.0,  0.75, 1.0),
		Color(1.0, 0.78, 0.18, 0.80),
		Color(1.0, 0.38, 0.02, 0.0),
	])
	g.offsets = PackedFloat32Array([0.0, 0.38, 1.0])
	return g

func _spark_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors  = PackedColorArray([
		Color(1.0, 1.0,  0.70, 1.0),
		Color(1.0, 0.60, 0.10, 0.85),
		Color(0.55, 0.08, 0.0,  0.0),
	])
	g.offsets = PackedFloat32Array([0.0, 0.38, 1.0])
	return g

func _smoke_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors  = PackedColorArray([
		Color(0.22, 0.16, 0.12, 0.0),
		Color(0.18, 0.13, 0.10, 0.28),
		Color(0.10, 0.07, 0.05, 0.0),
	])
	g.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	return g

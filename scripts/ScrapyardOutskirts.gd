extends Node3D

const _FLICKER = preload("res://scripts/ForgeLightFlicker.gd")

const INNER: float = 50.0
const OUTER: float = 116.0

# ── Tekstury fasad (ładowane raz, dzielone między instancje) ──────────────────
const _FACADE_COLOR := [
	"res://assets/textures/facades/facade_01_color.png",
	"res://assets/textures/facades/facade_06_color.png",
	"res://assets/textures/facades/facade_18_color.png",
	"res://assets/textures/facades/facade_19_color.png",
	"res://assets/textures/facades/facade_20_color.png",
	"res://assets/textures/facades/factory_brick_color.png",
	"res://assets/textures/facades/factory_windows_color.png",
]
const _FACADE_NORMAL := [
	"res://assets/textures/facades/facade_01_normal.png",
	"res://assets/textures/facades/facade_06_normal.png",
	"res://assets/textures/facades/facade_18_normal.png",
	"res://assets/textures/facades/facade_19_normal.png",
	"res://assets/textures/facades/facade_20_normal.png",
	"res://assets/textures/facades/factory_brick_normal.png",
	"res://assets/textures/facades/factory_windows_normal.png",
]
const _FACADE_ROUGH := [
	"res://assets/textures/facades/facade_01_rough.png",
	"res://assets/textures/facades/facade_06_rough.png",
	"res://assets/textures/facades/facade_18_rough.png",
	"res://assets/textures/facades/facade_19_rough.png",
	"res://assets/textures/facades/facade_20_rough.png",
	"res://assets/textures/facades/factory_brick_rough.png",
	"res://assets/textures/facades/factory_windows_rough.png",
]

var _facade_mats: Array[StandardMaterial3D] = []
var _brick_mat: StandardMaterial3D
var _concrete_mat: StandardMaterial3D

func _ready() -> void:
	_build_facade_mats()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	_outer_ground()
	_build_ruins(rng)
	_build_large_structures()
	_build_scrap_mountains()
	_build_tanks()
	_build_beams()
	_build_chimneys()

func _build_facade_mats() -> void:
	for i in _FACADE_COLOR.size():
		var mat := StandardMaterial3D.new()
		var col_tex = load(_FACADE_COLOR[i])
		if col_tex:
			mat.albedo_texture = col_tex
		var nor_tex = load(_FACADE_NORMAL[i])
		if nor_tex:
			mat.normal_enabled = true
			mat.normal_texture = nor_tex
			mat.normal_scale = 1.2
		var rough_tex = load(_FACADE_ROUGH[i])
		if rough_tex:
			mat.roughness_texture = rough_tex
			mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		mat.roughness = 0.85
		mat.metallic = 0.05
		mat.uv1_scale = Vector3(1.0, 1.5, 1.0)
		_facade_mats.append(mat)

	# Ceglane mury ruin
	_brick_mat = StandardMaterial3D.new()
	var b = load("res://assets/textures/facades/brick_wall_color.jpg")
	if b: _brick_mat.albedo_texture = b
	_brick_mat.roughness = 0.92
	_brick_mat.metallic = 0.0
	_brick_mat.uv1_scale = Vector3(2.0, 2.0, 1.0)

	# Pęknięty beton
	_concrete_mat = StandardMaterial3D.new()
	var c = load("res://assets/textures/facades/concrete_crack_color.jpg")
	if c: _concrete_mat.albedo_texture = c
	_concrete_mat.roughness = 0.96
	_concrete_mat.metallic = 0.0
	_concrete_mat.uv1_scale = Vector3(1.5, 1.5, 1.0)

func _outer_ground() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(OUTER * 2.2, OUTER * 2.2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.26, 0.20, 0.13)
	mat.roughness = 0.97
	mat.metallic = 0.04
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.set_surface_override_material(0, mat)
	mi.position.y = -0.03
	add_child(mi)

func _build_ruins(rng: RandomNumberGenerator) -> void:
	for i in 18:
		var p   := _ring(rng, 54.0, 98.0)
		var w   := rng.randf_range(4.0, 18.0)
		var h   := rng.randf_range(2.5, 9.5)
		var d   := rng.randf_range(0.5, 2.5)
		var rot := rng.randf_range(-PI, PI)
		# Losuj między cegłą a betonem
		var mat: StandardMaterial3D
		if rng.randf() < 0.55:
			mat = _brick_mat.duplicate()
		else:
			mat = _concrete_mat.duplicate()
		# 30% szans na emissive — żarzące się szczeliny
		if rng.randf() < 0.30:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.30, 0.04)
			mat.emission_energy_multiplier = rng.randf_range(0.3, 1.2)
		_box_mi(p + Vector3(0, h * 0.5, 0), Vector3(w, h, d), rot, mat)

func _build_large_structures() -> void:
	if _facade_mats.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 8:
		var p   := _ring(rng, 65.0, 102.0)
		var w   := rng.randf_range(8.0, 20.0)
		var h   := rng.randf_range(10.0, 22.0)
		var d   := rng.randf_range(6.0, 14.0)
		var rot := rng.randf_range(-PI, PI)

		# Wybierz losową fasadę — skaluj UV żeby pasowały okna do rozmiaru budynku
		var mat: StandardMaterial3D = _facade_mats[rng.randi() % _facade_mats.size()].duplicate()
		# UV scale: h/4 powtórzeń w pionie daje ~4m/piętro
		mat.uv1_scale = Vector3(w / 4.0, h / 4.5, 1.0)

		# Ciepły pomarańczowy tint — smog i światło ognisk barwią budynki
		mat.albedo_color = Color(
			rng.randf_range(0.75, 0.95),
			rng.randf_range(0.65, 0.80),
			rng.randf_range(0.52, 0.68)
		)

		_box_mi(p + Vector3(0, h * 0.5, 0), Vector3(w, h, d), rot, mat)

		# Wyrostek/nadbudówka na dachu — ciekawsza sylwetka
		if rng.randf() < 0.65:
			var top_mat: StandardMaterial3D = _facade_mats[rng.randi() % _facade_mats.size()].duplicate()
			top_mat.albedo_color = mat.albedo_color.darkened(0.25)
			var tw := w * rng.randf_range(0.2, 0.5)
			var th := rng.randf_range(2.0, 6.0)
			var td := d * rng.randf_range(0.2, 0.5)
			top_mat.uv1_scale = Vector3(tw / 4.0, th / 4.0, 1.0)
			_box_mi(
				p + Vector3(rng.randf_range(-w * 0.2, w * 0.2), h + th * 0.5, 0),
				Vector3(tw, th, td), rot, top_mat
			)

		# Emissive blask okien — losowe budynki świecą od środka
		if rng.randf() < 0.55:
			var glow_mat := StandardMaterial3D.new()
			glow_mat.albedo_color = Color(1.0, 0.75, 0.35, 1.0)
			glow_mat.emission_enabled = true
			glow_mat.emission = Color(1.0, 0.55, 0.15)
			glow_mat.emission_energy_multiplier = rng.randf_range(1.2, 3.5)
			# Płaski panel "okna" na ścianie budynku
			var win_w := rng.randf_range(w * 0.3, w * 0.7)
			var win_h := rng.randf_range(1.2, 3.0)
			var win_z := d * 0.501
			var bm := BoxMesh.new()
			bm.size = Vector3(win_w, win_h, 0.05)
			var wmi := MeshInstance3D.new()
			wmi.mesh = bm
			wmi.set_surface_override_material(0, glow_mat)
			wmi.position = p + Vector3(0, h * rng.randf_range(0.3, 0.7), win_z)
			wmi.rotation.y = rot
			add_child(wmi)

func _build_scrap_mountains() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55
	for i in 14:
		var p := _ring(rng, 52.0, 92.0)
		var r := rng.randf_range(3.5, 12.0)
		var h := rng.randf_range(1.5, 7.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(
			rng.randf_range(0.50, 0.82),
			rng.randf_range(0.18, 0.38),
			rng.randf_range(0.04, 0.14)
		)
		mat.roughness = rng.randf_range(0.68, 0.92)
		mat.metallic = rng.randf_range(0.28, 0.68)
		_cyl_mi(p + Vector3(0, h * 0.5, 0), r * 0.25, r, h, mat)

func _build_tanks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 33
	for i in 10:
		var p := _ring(rng, 54.0, 88.0)
		var r := rng.randf_range(1.0, 3.0)
		var h := rng.randf_range(2.0, 7.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(
			rng.randf_range(0.28, 0.52),
			rng.randf_range(0.24, 0.44),
			rng.randf_range(0.16, 0.32)
		)
		mat.roughness = rng.randf_range(0.55, 0.80)
		mat.metallic = rng.randf_range(0.48, 0.80)
		_cyl_mi(p + Vector3(0, h * 0.5, 0), r, r * 1.05, h, mat)
		var cap := StandardMaterial3D.new()
		cap.albedo_color = mat.albedo_color.darkened(0.25)
		cap.roughness = 0.75
		cap.metallic = 0.65
		_cyl_mi(p + Vector3(0, h + 0.25, 0), r * 0.9, r * 1.1, 0.5, cap)

func _build_beams() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 18:
		var p   := _ring(rng, 52.0, 95.0)
		var l   := rng.randf_range(5.0, 18.0)
		var rot := rng.randf_range(-PI, PI)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.28, 0.18)
		mat.roughness = 0.85
		mat.metallic = 0.45
		_box_mi(p + Vector3(0, 0.28, 0), Vector3(l, 0.5, 0.5), rot, mat)

func _build_chimneys() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 10:
		var p := _ring(rng, 58.0, 94.0)
		var h := rng.randf_range(9.0, 17.0)
		var r := rng.randf_range(0.38, 0.58)

		var body := StandardMaterial3D.new()
		body.albedo_color = Color(0.26, 0.22, 0.18)
		body.roughness = 0.96
		body.metallic = 0.06
		_cyl_mi(p + Vector3(0, h * 0.5, 0), r * 0.88, r, h, body)

		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(0.7, 0.15, 0.03)
		glow.emission_enabled = true
		glow.emission = Color(1.0, 0.32, 0.05)
		glow.emission_energy_multiplier = rng.randf_range(2.0, 5.0)
		glow.roughness = 0.65
		_cyl_mi(p + Vector3(0, h - 0.4, 0), r * 1.18, r * 1.18, 0.65, glow)

		var cap := StandardMaterial3D.new()
		cap.albedo_color = Color(0.12, 0.10, 0.08)
		cap.roughness = 0.98
		_cyl_mi(p + Vector3(0, h + 0.18, 0), r * 1.45, r * 1.45, 0.45, cap)

		var smoke := CPUParticles3D.new()
		smoke.emitting = true
		smoke.amount = 10
		smoke.lifetime = 9.0
		smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		smoke.emission_box_extents = Vector3(r * 0.7, 0.08, r * 0.7)
		smoke.direction = Vector3(0.06, 1.0, 0.03)
		smoke.spread = 14.0
		smoke.gravity = Vector3(0.10, 0.05, 0.04)
		smoke.initial_velocity_min = 0.7
		smoke.initial_velocity_max = 2.2
		smoke.scale_amount_min = 0.20
		smoke.scale_amount_max = 0.90
		var grad := Gradient.new()
		grad.set_color(0, Color(0.22, 0.18, 0.15, 0.65))
		grad.set_color(1, Color(0.10, 0.08, 0.07, 0.0))
		smoke.color_ramp = grad
		smoke.position = p + Vector3(0, h + 0.6, 0)
		add_child(smoke)

		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.42, 0.08)
		light.light_energy = rng.randf_range(0.5, 1.2)
		light.omni_range = rng.randf_range(7.0, 14.0)
		light.shadow_enabled = false
		light.position = p + Vector3(0, h - 0.8, 0)
		light.set_script(_FLICKER)
		add_child(light)

# ── helpers ──────────────────────────────────────────────────────────────────

func _ring(rng: RandomNumberGenerator, mn: float, mx: float) -> Vector3:
	var a := rng.randf_range(0.0, TAU)
	var d := rng.randf_range(mn, mx)
	return Vector3(cos(a) * d, 0.0, sin(a) * d)

func _box_mi(pos: Vector3, sz: Vector3, rot_y: float, mat: StandardMaterial3D) -> void:
	var mesh := BoxMesh.new()
	mesh.size = sz
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	mi.position   = pos
	mi.rotation.y = rot_y
	add_child(mi)

func _cyl_mi(pos: Vector3, r_top: float, r_bot: float, h: float, mat: StandardMaterial3D) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius    = r_top
	mesh.bottom_radius = r_bot
	mesh.height        = h
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)
	mi.position = pos
	add_child(mi)

extends DirectionalLight3D

var _time: float = 0.3   # 0=noc, 0.25=wschód, 0.5=południe, 0.75=zachód
var _env: Environment = null

# Kolory nieba w ciągu dnia
const SKY_TOP: Array = [
	Color(0.02, 0.02, 0.08),   # noc
	Color(0.12, 0.06, 0.22),   # wschód
	Color(0.08, 0.14, 0.38),   # dzień
	Color(0.06, 0.04, 0.14),   # zachód (obecny klimat)
]
const SKY_HOR: Array = [
	Color(0.04, 0.03, 0.10),   # noc
	Color(0.85, 0.30, 0.06),   # wschód
	Color(0.55, 0.72, 0.90),   # dzień
	Color(0.88, 0.28, 0.04),   # zachód
]
const AMB_COL: Array = [
	Color(0.04, 0.04, 0.12),   # noc
	Color(0.20, 0.10, 0.06),   # wschód
	Color(0.28, 0.22, 0.16),   # dzień
	Color(0.22, 0.10, 0.04),   # zachód
]

func _ready() -> void:
	await get_tree().process_frame
	var we: Node = get_tree().current_scene.get_node_or_null("WorldEnvironment")
	if we and we is WorldEnvironment:
		_env = (we as WorldEnvironment).environment

func _process(delta: float) -> void:
	_time += delta * 0.0033
	if _time > 1.0: _time -= 1.0

	# Oświetlenie kierunkowe
	light_energy = lerpf(0.05, 1.1, maxf(sin(_time * PI), 0.0))
	var t := _time
	if   t < 0.25: light_color = Color(0.15, 0.2, 0.4).lerp(Color(1.0, 0.45, 0.15), t / 0.25)
	elif t < 0.5:  light_color = Color(1.0, 0.45, 0.15).lerp(Color(1.0, 0.88, 0.65), (t - 0.25) / 0.25)
	elif t < 0.75: light_color = Color(1.0, 0.88, 0.65).lerp(Color(1.0, 0.45, 0.15), (t - 0.5) / 0.25)
	else:          light_color = Color(1.0, 0.45, 0.15).lerp(Color(0.15, 0.2, 0.4),  (t - 0.75) / 0.25)
	rotation_degrees.x = lerpf(-17.0, -70.0, sin(_time * PI))

	if not _env:
		return

	# Indeks (0=noc 1=wschód 2=dzień 3=zachód) z płynnym przejściem
	var sky_t: float
	var idx_a: int
	var idx_b: int
	if   t < 0.25: idx_a = 0; idx_b = 1; sky_t = t / 0.25
	elif t < 0.5:  idx_a = 1; idx_b = 2; sky_t = (t - 0.25) / 0.25
	elif t < 0.75: idx_a = 2; idx_b = 3; sky_t = (t - 0.5) / 0.25
	else:          idx_a = 3; idx_b = 0; sky_t = (t - 0.75) / 0.25

	var sky_top: Color = SKY_TOP[idx_a].lerp(SKY_TOP[idx_b], sky_t)
	var sky_hor: Color = SKY_HOR[idx_a].lerp(SKY_HOR[idx_b], sky_t)
	var amb:     Color = AMB_COL[idx_a].lerp(AMB_COL[idx_b], sky_t)

	var sky_mat := _env.sky.sky_material as ProceduralSkyMaterial
	if sky_mat:
		sky_mat.sky_top_color      = sky_top
		sky_mat.sky_horizon_color  = sky_hor
		sky_mat.ground_horizon_color = sky_hor.darkened(0.55)

	_env.ambient_light_color  = amb
	_env.ambient_light_energy = lerpf(0.20, 0.55, maxf(sin(_time * PI), 0.0))

	# Mgła — gęstsza w nocy
	var fog_night := Color(0.01, 0.01, 0.04)
	var fog_day   := Color(0.45, 0.16, 0.03)
	_env.fog_light_color = fog_night.lerp(fog_day, maxf(sin(_time * PI), 0.0))
	_env.fog_density     = lerpf(0.028, 0.014, maxf(sin(_time * PI), 0.0))

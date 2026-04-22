extends DirectionalLight3D

signal is_night_changed(night: bool)

var _time: float = 0.5   # 0=noc, 0.25=wschód, 0.5=południe, 0.75=zachód
var _env: Environment = null
var is_night: bool = false

const SKY_TOP: Array = [
	Color(0.01, 0.01, 0.06),   # noc
	Color(0.10, 0.06, 0.22),   # wschód
	Color(0.13, 0.38, 0.75),   # dzień — jasny błękit
	Color(0.06, 0.04, 0.14),   # zachód
]
const SKY_HOR: Array = [
	Color(0.03, 0.03, 0.09),   # noc
	Color(0.90, 0.40, 0.08),   # wschód — pomarańcz
	Color(0.60, 0.80, 0.96),   # dzień — jasnoniebieski
	Color(0.92, 0.32, 0.05),   # zachód — czerwień
]
const AMB_COL: Array = [
	Color(0.05, 0.05, 0.14),   # noc
	Color(0.62, 0.46, 0.30),   # wschód
	Color(0.88, 0.90, 0.95),   # dzień — neutralne jasne
	Color(0.68, 0.46, 0.24),   # zachód
]

func _ready() -> void:
	await get_tree().process_frame
	var we: Node = get_tree().current_scene.get_node_or_null("WorldEnvironment")
	if we and we is WorldEnvironment:
		_env = (we as WorldEnvironment).environment

func _process(delta: float) -> void:
	_time += delta * 0.0033
	if _time > 1.0: _time -= 1.0

	var night_now: bool = _time > 0.75 or _time < 0.25
	if night_now != is_night:
		is_night = night_now
		is_night_changed.emit(is_night)
		GameManager.notification.emit("🌙 Night falls..." if is_night else "☀️ Dawn breaks.")

	# Oświetlenie kierunkowe
	light_energy = lerpf(0.04, 3.2, maxf(sin(_time * PI), 0.0))
	var t := _time
	if   t < 0.25: light_color = Color(0.20, 0.25, 0.50).lerp(Color(1.0, 0.55, 0.20), t / 0.25)
	elif t < 0.5:  light_color = Color(1.0, 0.55, 0.20).lerp(Color(1.0, 0.95, 0.80), (t - 0.25) / 0.25)
	elif t < 0.75: light_color = Color(1.0, 0.95, 0.80).lerp(Color(1.0, 0.50, 0.18), (t - 0.5) / 0.25)
	else:          light_color = Color(1.0, 0.50, 0.18).lerp(Color(0.20, 0.25, 0.50), (t - 0.75) / 0.25)
	rotation_degrees.x = lerpf(-15.0, -72.0, sin(_time * PI))

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
	_env.ambient_light_energy = lerpf(0.20, 2.4, maxf(sin(_time * PI), 0.0))

	# Mgła — gęstsza w nocy + bonus od pogody
	var fog_night := Color(0.01, 0.01, 0.05)
	var fog_day   := Color(0.65, 0.72, 0.78)
	_env.fog_light_color = fog_night.lerp(fog_day, maxf(sin(_time * PI), 0.0))
	var base_fog := lerpf(0.022, 0.004, maxf(sin(_time * PI), 0.0))
	var ws := get_node_or_null("/root/WeatherSystem")
	var weather_fog := 0.0
	if ws:
		match ws.current_weather:
			"foggy": weather_fog = 0.045
			"rain":  weather_fog = 0.012
			"storm": weather_fog = 0.020
	_env.fog_density = base_fog + weather_fog

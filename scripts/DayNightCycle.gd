extends DirectionalLight3D

signal is_night_changed(night: bool)

var _time: float = 0.68  # start bliski zachodu słońca — dramatyczny wygląd
var _env: Environment = null
var is_night: bool = false

# Industrialne, zanieczyszczone niebo — nie czyste lato
const SKY_TOP: Array = [
	Color(0.02, 0.01, 0.03, 1),   # noc
	Color(0.06, 0.03, 0.01, 1),   # wschód
	Color(0.10, 0.08, 0.06, 1),   # dzień — zadymiony
	Color(0.04, 0.02, 0.01, 1),   # zachód
]
const SKY_HOR: Array = [
	Color(0.08, 0.04, 0.01, 1),   # noc — żar w tle
	Color(0.92, 0.38, 0.06, 1),   # wschód — płomień
	Color(0.62, 0.40, 0.20, 1),   # dzień — smog
	Color(0.98, 0.20, 0.03, 1),   # zachód — krew
]
const AMB_COL: Array = [
	Color(0.10, 0.05, 0.08, 1),   # noc
	Color(0.55, 0.32, 0.14, 1),   # wschód
	Color(0.70, 0.50, 0.28, 1),   # dzień
	Color(0.65, 0.28, 0.10, 1),   # zachód
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
		GameManager.notification.emit("🌙 Night falls..." if is_night else "🌅 Dawn breaks.")

	light_energy = lerpf(0.04, 2.8, maxf(sin(_time * PI), 0.0))
	var t := _time
	if   t < 0.25: light_color = Color(0.18, 0.20, 0.45).lerp(Color(1.0, 0.52, 0.18), t / 0.25)
	elif t < 0.5:  light_color = Color(1.0, 0.52, 0.18).lerp(Color(1.0, 0.85, 0.62), (t - 0.25) / 0.25)
	elif t < 0.75: light_color = Color(1.0, 0.85, 0.62).lerp(Color(1.0, 0.42, 0.10), (t - 0.5) / 0.25)
	else:          light_color = Color(1.0, 0.42, 0.10).lerp(Color(0.18, 0.20, 0.45), (t - 0.75) / 0.25)
	rotation_degrees.x = lerpf(-10.0, -68.0, sin(_time * PI))

	if not _env:
		return

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
		sky_mat.sky_top_color        = sky_top
		sky_mat.sky_horizon_color    = sky_hor
		sky_mat.ground_horizon_color = sky_hor.darkened(0.50)

	_env.ambient_light_color  = amb
	_env.ambient_light_energy = lerpf(0.25, 2.2, maxf(sin(_time * PI), 0.0))

	# Smog przez cały dzień, gęsty w nocy
	var fog_night := Color(0.04, 0.02, 0.06)
	var fog_day   := Color(0.58, 0.38, 0.18)
	_env.fog_light_color = fog_night.lerp(fog_day, maxf(sin(_time * PI), 0.0))
	var base_fog := lerpf(0.020, 0.006, maxf(sin(_time * PI), 0.0))
	var ws := get_node_or_null("/root/WeatherSystem")
	var weather_fog := 0.0
	if ws:
		match ws.current_weather:
			"foggy": weather_fog = 0.045
			"rain":  weather_fog = 0.012
			"storm": weather_fog = 0.022
	_env.fog_density = base_fog + weather_fog

	# Glow mocniejszy nocą — ogniska błyszczą bardziej
	_env.glow_intensity = lerpf(1.8, 0.9, maxf(sin(_time * PI), 0.0))

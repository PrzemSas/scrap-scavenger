extends Control

const WORLD_HALF := 44.0

var _t: float = 0.0
var _scrap: Array = []
var _piles: Array = []
var _player_pos: Vector2 = Vector2.ZERO
var _player_rot: float = 0.0
var _gate_pos: Vector2 = Vector2(-999, -999)
var _forge_pos: Vector2 = Vector2(-999, -999)

const PILE_COLORS := [Color("#8B4513"), Color("#ffff00"), Color("#333333")]
const RARITY_COLORS := [Color("#666666"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]

func _ready() -> void:
	var d := get_node_or_null("MapBG/Dots")
	if d: d.visible = false
	var pd := get_node_or_null("MapBG/PlayerDot")
	if pd: pd.visible = false

func _world_to_map(wx: float, wz: float) -> Vector2:
	var map_rect: Rect2 = $MapBG.get_rect()
	var nx: float = (wx / WORLD_HALF * 0.5 + 0.5) * map_rect.size.x
	var ny: float = (wz / WORLD_HALF * 0.5 + 0.5) * map_rect.size.y
	return map_rect.position + Vector2(nx, ny)

func _process(delta: float) -> void:
	_t += delta
	if _t < 0.2:
		return
	_t = 0.0

	_scrap.clear()
	_piles.clear()

	var sm := get_tree().current_scene.get_node_or_null("SpawnManager")
	if sm:
		for ch in sm.get_children():
			if ch is Area3D:
				var r := 0
				if "scrap_data" in ch: r = ch.scrap_data.get("rarity", 0)
				_scrap.append({"pos": _world_to_map(ch.position.x, ch.position.z), "rarity": r})

	var jp := get_tree().current_scene.get_node_or_null("JunkPiles")
	if jp:
		var pile_list = jp.get("_piles")
		if pile_list != null:
			for pd in pile_list:
				var state := 0
				if pd.searching: state = 1
				elif pd.cooldown > 0.0: state = 2
				_piles.append({"pos": _world_to_map(pd.spawn_pos.x, pd.spawn_pos.z), "state": state})

	var player := get_tree().current_scene.get_node_or_null("Player")
	if player:
		_player_pos = _world_to_map(player.global_position.x, player.global_position.z)
		_player_rot = player.rotation.y

	var gate := get_tree().current_scene.get_node_or_null("ReturnGate")
	if gate:
		_gate_pos = _world_to_map(gate.global_position.x, gate.global_position.z)

	var forge := get_tree().current_scene.get_node_or_null("ForgeStructure")
	if forge:
		_forge_pos = _world_to_map(forge.global_position.x, forge.global_position.z)

	queue_redraw()

func _draw() -> void:
	var map_rect: Rect2 = $MapBG.get_rect()
	var border_c := Color(1.0, 0.42, 0.0, 0.65)
	var corner_c := Color(1.0, 0.60, 0.1, 0.95)

	# Outer border
	draw_rect(map_rect, border_c, false, 1.5)

	# Industrial corner ticks
	const TICK := 7.0
	var corners_data := [
		[map_rect.position,                                 Vector2(1, 0),  Vector2(0, 1)],
		[map_rect.position + Vector2(map_rect.size.x, 0),  Vector2(-1, 0), Vector2(0, 1)],
		[map_rect.position + map_rect.size,                 Vector2(-1, 0), Vector2(0, -1)],
		[map_rect.position + Vector2(0, map_rect.size.y),  Vector2(1, 0),  Vector2(0, -1)],
	]
	for cd in corners_data:
		var cp: Vector2 = cd[0]
		var dx: Vector2 = cd[1]
		var dy: Vector2 = cd[2]
		draw_line(cp, cp + dx * TICK, corner_c, 2.0)
		draw_line(cp, cp + dy * TICK, corner_c, 2.0)

	# Junk piles (filled circles)
	for p in _piles:
		draw_circle(p.pos, 4.5, PILE_COLORS[p.state])

	# Scrap items (circles sized by rarity)
	for s in _scrap:
		var r: int = s.rarity
		draw_circle(s.pos, 2.0 + r * 0.8, RARITY_COLORS[r])

	# Forge marker — orange filled square with bright outline
	if _forge_pos.x > -900:
		draw_rect(Rect2(_forge_pos - Vector2(4, 4), Vector2(8, 8)), Color(1.0, 0.42, 0.0, 0.85))
		draw_rect(Rect2(_forge_pos - Vector2(4, 4), Vector2(8, 8)), Color(1.0, 0.75, 0.2, 1.0), false, 1.2)

	# Gate marker — green diamond
	if _gate_pos.x > -900:
		var gp := _gate_pos
		var gpts := PackedVector2Array([
			gp + Vector2(0, -5.5),
			gp + Vector2(5.5, 0),
			gp + Vector2(0, 5.5),
			gp + Vector2(-5.5, 0),
		])
		draw_colored_polygon(gpts, [Color(0.18, 1.0, 0.25, 0.9), Color(0.18, 1.0, 0.25, 0.9),
									Color(0.18, 1.0, 0.25, 0.9), Color(0.18, 1.0, 0.25, 0.9)])
		draw_polyline(PackedVector2Array([gpts[0], gpts[1], gpts[2], gpts[3], gpts[0]]),
					  Color(0.5, 1.0, 0.5, 0.8), 1.0)

	# Player — directional triangle
	var fwd := Vector2(-sin(_player_rot), -cos(_player_rot))
	var right := Vector2(fwd.y, -fwd.x)
	var pts := PackedVector2Array([
		_player_pos + fwd * 7.5,
		_player_pos - fwd * 4.0 + right * 4.5,
		_player_pos - fwd * 4.0 - right * 4.5,
	])
	draw_colored_polygon(pts, [Color(0.22, 1.0, 0.08, 1.0),
							   Color(0.22, 1.0, 0.08, 0.75),
							   Color(0.22, 1.0, 0.08, 0.75)])
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]),
				  Color(0.6, 1.0, 0.4, 0.9), 1.2)

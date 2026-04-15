extends Control

const WORLD_HALF := 44.0

var _t: float = 0.0
var _scrap: Array = []   # Array of {pos: Vector2, rarity: int}
var _piles: Array = []   # Array of {pos: Vector2, state: int}  0=ok 1=searching 2=cooldown
var _player_pos: Vector2 = Vector2.ZERO

const PILE_COLORS := [Color("#8B4513"), Color("#ffff00"), Color("#333333")]
const RARITY_COLORS := [Color("#666666"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]

func _ready() -> void:
	# Stare node'y — zastąpione przez _draw()
	var d := get_node_or_null("MapBG/Dots")
	if d: d.visible = false
	var pd := get_node_or_null("MapBG/PlayerDot")
	if pd: pd.visible = false

func _world_to_map(wx: float, wz: float) -> Vector2:
	var map_rect := $MapBG.get_rect()
	var nx := (wx / WORLD_HALF * 0.5 + 0.5) * map_rect.size.x
	var ny := (wz / WORLD_HALF * 0.5 + 0.5) * map_rect.size.y
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

	queue_redraw()

func _draw() -> void:
	for s in _scrap:
		draw_rect(Rect2(s.pos - Vector2(2.5, 2.5), Vector2(5, 5)), RARITY_COLORS[s.rarity])
	for p in _piles:
		draw_rect(Rect2(p.pos - Vector2(3.5, 3.5), Vector2(7, 7)), PILE_COLORS[p.state])
	draw_rect(Rect2(_player_pos - Vector2(4, 4), Vector2(8, 8)), Color(0.22, 1.0, 0.08, 1.0))

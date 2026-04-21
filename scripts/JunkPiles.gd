extends Node3D

const SEARCH_TIME := 2.0   # sekundy szukania
const COOLDOWN    := 30.0  # cooldown po przeszukaniu
const SPAWN_COUNT := 5     # ile itemów wypada
const RANGE       := 4.0   # zasięg wykrycia gracza

const SCRAP_SCENE = preload("res://scenes/objects/ScrapItem.tscn")

# Modele dekoracyjne wyrastające z kupki
const TYRE_SCENE = preload("res://assets/models/polyhaven/old_tyre/old_tyre_2k.glb")
const RIM_SCENE  = preload("res://assets/models/polyhaven/rusted_wheel_rim_01/rusted_wheel_rim_01_2k.glb")

class PileData:
	var mesh: MeshInstance3D
	var position: Vector3      # local position (origin do shake reset)
	var spawn_pos: Vector3     # global position (do spawnu itemów)
	var cooldown: float = 0.0      # czas do następnego szukania
	var searching: bool = false
	var search_t: float = 0.0
	var mat_orig: Material
	var area: Area3D

var _piles: Array = []            # Array[PileData]
var _nearest: PileData = null
var _in_range: bool = false
var _spawn_parent: Node3D = null  # SpawnManager lub parent

# Matriały cooldown
var _mat_depleted: StandardMaterial3D

func _ready() -> void:
	_mat_depleted = StandardMaterial3D.new()
	_mat_depleted.albedo_color = Color(0.28, 0.18, 0.12, 1.0)
	_mat_depleted.roughness = 1.0
	_mat_depleted.metallic = 0.0

	for child in get_children():
		if not (child is MeshInstance3D):
			continue
		var mesh := child as MeshInstance3D
		var pd := PileData.new()
		pd.mesh = mesh
		pd.position = mesh.position          # local
		pd.spawn_pos = mesh.global_position  # global (ustawiamy po frame)
		pd.mat_orig = mesh.get_surface_override_material(0)

		# Area3D do detekcji gracza
		var area := Area3D.new()
		area.collision_layer = 0
		area.collision_mask = 1  # player layer
		var cs := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = RANGE
		cs.shape = sphere
		area.add_child(cs)
		mesh.add_child(area)
		pd.area = area

		# StaticBody do kolizji świata
		var body := StaticBody3D.new()
		body.transform = mesh.transform
		add_child(body)
		var bcs := CollisionShape3D.new()
		var bshape := BoxShape3D.new()
		bshape.size = (mesh.mesh as BoxMesh).size if mesh.mesh is BoxMesh else Vector3(2,1,2)
		bcs.shape = bshape
		body.add_child(bcs)

		_add_visual_junk(mesh)
		_piles.append(pd)

	await get_tree().process_frame
	# Aktualizuj globalne pozycje po wyrenderowaniu
	for pd in _piles:
		pd.spawn_pos = pd.mesh.global_position
	_spawn_parent = get_tree().get_root().find_child("SpawnManager", true, false)

func _process(delta: float) -> void:
	var player := _find_player()
	_nearest = null
	_in_range = false

	if player:
		var best_dist := INF
		for pd in _piles:
			if pd.searching:
				continue
			var d: float = (pd.mesh.global_position - player.global_position).length()
			if d < RANGE and d < best_dist:
				best_dist = d
				_nearest = pd
		_in_range = _nearest != null

	# Update cooldowns
	for pd in _piles:
		if pd.cooldown > 0.0:
			pd.cooldown -= delta
			if pd.cooldown <= 0.0:
				pd.cooldown = 0.0
				pd.mesh.set_surface_override_material(0, pd.mat_orig)

	# Update searching piles — shake animation
	for pd in _piles:
		if not pd.searching:
			continue
		pd.search_t += delta
		var progress: float = pd.search_t / SEARCH_TIME
		GameManager.pile_search_progress.emit(progress)
		# Shake: amplituda i częstotliwość rosną z postępem
		var shake_amp: float = 0.04 + progress * 0.10
		var freq: float = 10.0 + progress * 22.0
		var ox: float = sin(pd.search_t * freq * TAU) * shake_amp
		var oz: float = cos(pd.search_t * freq * 1.3 * TAU) * shake_amp * 0.5
		pd.mesh.position = pd.position + Vector3(ox, 0.0, oz)
		if pd.search_t >= SEARCH_TIME:
			pd.mesh.position = pd.position  # reset do oryginału
			_finish_search(pd)
			return

	# Hint UI
	if _in_range and _nearest != null and _nearest.cooldown <= 0.0:
		GameManager.pile_hint_changed.emit("[E] Search pile")
	elif _nearest != null and _nearest.cooldown > 0.0:
		GameManager.pile_hint_changed.emit("Cooldown: %ds" % int(_nearest.cooldown + 1.0))
	else:
		GameManager.pile_hint_changed.emit("")

	# E key
	if _in_range and _nearest != null and _nearest.cooldown <= 0.0:
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			_start_search(_nearest)

func _start_search(pd: PileData) -> void:
	pd.searching = true
	pd.search_t = 0.0
	GameManager.pile_search_progress.emit(0.0)
	GameManager.notification.emit("Searching pile...")
	AudioManager.play_collect()

func _finish_search(pd: PileData) -> void:
	pd.searching = false
	pd.search_t = 0.0
	pd.cooldown = COOLDOWN
	pd.mesh.set_surface_override_material(0, _mat_depleted)
	GameManager.pile_search_progress.emit(-1.0)
	GameManager.pile_hint_changed.emit("")

	# Spawn itemów
	var sm := _spawn_parent
	if sm and sm.has_method("_roll_scrap"):
		for i in SPAWN_COUNT:
			var scrap := SCRAP_SCENE.instantiate()
			var offset := Vector3(randf_range(-1.5, 1.5), 0.5, randf_range(-1.5, 1.5))
			scrap.position = pd.spawn_pos + offset
			if sm:
				sm.add_child(scrap)
			else:
				add_child(scrap)
			scrap.setup(sm._roll_scrap())
	else:
		# Fallback — prosty spawn
		for i in SPAWN_COUNT:
			var scrap := SCRAP_SCENE.instantiate()
			var offset := Vector3(randf_range(-2.0, 2.0), 0.5, randf_range(-2.0, 2.0))
			scrap.position = pd.mesh.global_position + offset
			add_child(scrap)
			if scrap.has_method("setup"):
				scrap.setup({"id":"can","name":"Aluminum Can","value":1,"rarity":0})

	GameManager.notification.emit("+%d scrap found!" % SPAWN_COUNT)

func _add_visual_junk(pile: MeshInstance3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pile.position)

	var base: Vector3 = Vector3(2, 1, 2)
	if pile.mesh is BoxMesh:
		base = (pile.mesh as BoxMesh).size

	var mat: Material = pile.get_surface_override_material(0)

	# Blachy/belki sterczące pod kątem
	var sheet_count := rng.randi_range(5, 9)
	for i in sheet_count:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var style := rng.randi_range(0, 2)
		match style:
			0: # płaska blacha
				bm.size = Vector3(rng.randf_range(0.4, base.x * 0.7),
								  rng.randf_range(0.06, 0.18),
								  rng.randf_range(0.3, base.z * 0.6))
			1: # pionowa belka
				bm.size = Vector3(rng.randf_range(0.12, 0.28),
								  rng.randf_range(0.4, base.y * 1.4),
								  rng.randf_range(0.12, 0.28))
			2: # rura/pręt
				bm.size = Vector3(rng.randf_range(0.1, 0.22),
								  rng.randf_range(0.3, 0.16),
								  rng.randf_range(0.5, base.z * 0.9))
		mi.mesh = bm
		mi.set_surface_override_material(0, mat)

		var px := rng.randf_range(-base.x * 0.45, base.x * 0.45)
		var py := rng.randf_range(base.y * 0.2, base.y * 0.55)
		var pz := rng.randf_range(-base.z * 0.45, base.z * 0.45)
		mi.position = Vector3(px, py, pz)

		mi.rotation.y = rng.randf_range(-PI, PI)
		mi.rotation.x = rng.randf_range(-0.55, 0.55)
		mi.rotation.z = rng.randf_range(-0.45, 0.45)
		pile.add_child(mi)

	# Małe detale na wierzchu (kawałki metalu)
	var chunk_count := rng.randi_range(3, 6)
	for i in chunk_count:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(rng.randf_range(0.15, 0.45),
						  rng.randf_range(0.1, 0.3),
						  rng.randf_range(0.15, 0.4))
		mi.mesh = bm
		mi.set_surface_override_material(0, mat)
		mi.position = Vector3(
			rng.randf_range(-base.x * 0.4, base.x * 0.4),
			base.y * 0.5 + rng.randf_range(0.0, 0.25),
			rng.randf_range(-base.z * 0.4, base.z * 0.4)
		)
		mi.rotation = Vector3(rng.randf_range(-PI, PI),
							  rng.randf_range(-PI, PI),
							  rng.randf_range(-PI, PI))
		pile.add_child(mi)

	# Co trzecia kupa dostaje oponę lub felgę
	if rng.randi_range(0, 2) == 0:
		var prop_scene := TYRE_SCENE if rng.randi_range(0, 1) == 0 else RIM_SCENE
		var prop: Node3D = prop_scene.instantiate()
		prop.position = Vector3(
			rng.randf_range(-base.x * 0.35, base.x * 0.35),
			base.y * 0.45,
			rng.randf_range(-base.z * 0.35, base.z * 0.35)
		)
		prop.rotation.y = rng.randf_range(-PI, PI)
		prop.rotation.x = rng.randf_range(-0.8, 0.8)
		prop.scale = Vector3.ONE * rng.randf_range(0.55, 0.85)
		pile.add_child(prop)

func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node3D
	return null

extends Area3D
const SPARKS_SCENE = preload("res://scenes/effects/CollectSparks.tscn")
const POPUP_SCENE = preload("res://scenes/effects/CoinPopup.tscn")
var scrap_data: Dictionary = {}
var _bob_time: float = 0.0
var _initial_y: float = 0.0
var _hovered: bool = false
var _base_emission: float = 0.5
func setup(data: Dictionary) -> void:
	scrap_data = data; _initial_y = position.y
	var mi = $MeshInstance3D; var cs = $CollisionShape3D
	var r = data.get("rarity", 0)
	var colors = [Color("#888888"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]
	var id = data.get("id", "can")
	match id:
		"can": var m=CylinderMesh.new(); m.top_radius=.12; m.bottom_radius=.12; m.height=.3; mi.mesh=m; var s=CylinderShape3D.new(); s.radius=.15; s.height=.35; cs.shape=s
		"bolt": var m=CylinderMesh.new(); m.top_radius=.08; m.bottom_radius=.08; m.height=.25; mi.mesh=m; var s=CylinderShape3D.new(); s.radius=.1; s.height=.3; cs.shape=s
		"pipe": var m=CylinderMesh.new(); m.top_radius=.06; m.bottom_radius=.06; m.height=.6; mi.mesh=m; mi.rotation.z=PI/2; var s=BoxShape3D.new(); s.size=Vector3(.6,.15,.15); cs.shape=s
		"cable": var m=TorusMesh.new(); m.inner_radius=.06; m.outer_radius=.18; mi.mesh=m; var s=SphereShape3D.new(); s.radius=.2; cs.shape=s
		"battery": var m=BoxMesh.new(); m.size=Vector3(.25,.35,.15); mi.mesh=m; var s=BoxShape3D.new(); s.size=Vector3(.3,.4,.2); cs.shape=s
		"motor": var m=CylinderMesh.new(); m.top_radius=.2; m.bottom_radius=.2; m.height=.3; mi.mesh=m; var s=CylinderShape3D.new(); s.radius=.22; s.height=.35; cs.shape=s
		"gold": var m=PrismMesh.new(); m.size=Vector3(.3,.3,.3); mi.mesh=m; var s=BoxShape3D.new(); s.size=Vector3(.35,.35,.35); cs.shape=s
		_: var m=BoxMesh.new(); m.size=Vector3(.3,.3,.3); mi.mesh=m
	_base_emission = .5 + r * .4
	var mat = StandardMaterial3D.new()
	mat.albedo_color=colors[r]; mat.emission_enabled=true; mat.emission=colors[r]
	mat.emission_energy_multiplier=_base_emission; mat.metallic=.3+r*.15; mat.roughness=.7-r*.1
	mi.material_override = mat
	if r >= 2: mi.scale = Vector3(1.4,1.4,1.4)
	if r >= 3: mi.scale = Vector3(1.8,1.8,1.8)
	if $NameLabel: $NameLabel.text=data.get("name",""); $NameLabel.modulate=colors[r]
	if $ValueLabel: $ValueLabel.text="+%dc" % (data.get("value",1)*GameManager.click_power); $ValueLabel.modulate=Color(1,.84,0,0)
func _process(delta: float) -> void:
	_bob_time += delta
	position.y = _initial_y + .5 + sin(_bob_time*2)*.1
	if scrap_data.get("rarity",0) >= 3: rotation.y += delta*1.5
	elif scrap_data.get("rarity",0) >= 2: rotation.y += delta*.5
	var mat = $MeshInstance3D.material_override
	if mat: mat.emission_energy_multiplier = _base_emission + (sin(_bob_time*6)*.3+.5 if _hovered else 0)
func _on_input_event(_c,event,_p,_n,_i) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT: collect()
func _on_mouse_entered() -> void:
	_hovered=true; if $ValueLabel: $ValueLabel.modulate.a=.9
func _on_mouse_exited() -> void:
	_hovered=false; if $ValueLabel: $ValueLabel.modulate.a=0
func collect() -> void:
	var base = scrap_data.get("value",1)*GameManager.click_power
	var combo = get_tree().current_scene.get_node_or_null("ComboSystem")
	var cm = 1.0
	if combo and combo.has_method("get_multiplier"): cm = combo.get_multiplier()
	var value = int(base*cm)
	for i in GameManager.click_power:
		if GameManager.inventory.size() < GameManager.max_slots: GameManager.add_to_inventory(scrap_data.duplicate())
	GameManager.add_coins(value); AudioManager.play_collect()
	var r = scrap_data.get("rarity",0)
	var colors = [Color("#888888"),Color("#ff6a00"),Color("#00e5ff"),Color("#FFD700")]
	if r >= 2:
		var cam = get_tree().current_scene.get_node_or_null("Camera3D")
		if cam and cam.has_method("shake"): cam.shake(1.0 + r * 1.5)
	var sparks = SPARKS_SCENE.instantiate()
	sparks.position=global_position; sparks.color=colors[r]; sparks.amount=16+r*8; sparks.emitting=true
	get_tree().current_scene.add_child(sparks)
	get_tree().create_timer(1.0).timeout.connect(sparks.queue_free)
	var popup = POPUP_SCENE.instantiate()
	popup.position=global_position+Vector3(0,1,0)
	popup.setup(value, Color("#FFD700") if cm>1 else colors[r])
	get_tree().current_scene.add_child(popup); queue_free()

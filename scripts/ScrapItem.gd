extends Area3D
const SPARKS=preload("res://scenes/effects/CollectSparks.tscn")
const POPUP=preload("res://scenes/effects/CoinPopup.tscn")
const AURA=preload("res://scenes/effects/RarityAura.tscn")
var scrap_data:Dictionary={}
var _bob:float=0.0
var _iy:float=0.0
var _collected:bool=false
func _ready()->void:
	body_entered.connect(_on_body_entered)
func _on_body_entered(body:Node3D)->void:
	if body.is_in_group("player"): collect()
func setup(data:Dictionary)->void:
	scrap_data=data; _iy=position.y
	var mi:MeshInstance3D=$MeshInstance3D
	var r:int=data.get("rarity",0)
	var cl:Array=[Color("#888"),Color("#ff6a00"),Color("#00e5ff"),Color("#FFD700")]
	match data.get("id","can"):
		"can":
			var m:=CylinderMesh.new(); m.top_radius=0.12; m.bottom_radius=0.12; m.height=0.3; mi.mesh=m
		"bolt":
			var m:=CylinderMesh.new(); m.top_radius=0.08; m.bottom_radius=0.08; m.height=0.25; mi.mesh=m
		"pipe":
			var m:=CylinderMesh.new(); m.top_radius=0.06; m.bottom_radius=0.06; m.height=0.6; mi.mesh=m; mi.rotation.z=PI/2
		"cable":
			var m:=TorusMesh.new(); m.inner_radius=0.06; m.outer_radius=0.18; mi.mesh=m
		"battery":
			var m:=BoxMesh.new(); m.size=Vector3(0.25,0.35,0.15); mi.mesh=m
		"chip":
			var m:=BoxMesh.new(); m.size=Vector3(0.2,0.05,0.15); mi.mesh=m
		"coil":
			var m:=TorusMesh.new(); m.inner_radius=0.04; m.outer_radius=0.15; mi.mesh=m
		"motor":
			var m:=CylinderMesh.new(); m.top_radius=0.2; m.bottom_radius=0.2; m.height=0.3; mi.mesh=m
		"gear":
			var m:=CylinderMesh.new(); m.top_radius=0.18; m.bottom_radius=0.18; m.height=0.08; mi.mesh=m
		"gold":
			var m:=PrismMesh.new(); m.size=Vector3(0.3,0.3,0.3); mi.mesh=m
		"crystal":
			var m:=PrismMesh.new(); m.size=Vector3(0.2,0.4,0.2); mi.mesh=m
		_:
			var m:=BoxMesh.new(); m.size=Vector3(0.3,0.3,0.3); mi.mesh=m
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=cl[r]; mat.emission_enabled=true; mat.emission=cl[r]
	mat.emission_energy_multiplier=0.5+r*0.4; mat.metallic=0.3+r*0.15; mat.roughness=0.7-r*0.1
	mi.material_override=mat
	if r>=2: mi.scale=Vector3(1.4,1.4,1.4)
	if r>=3: mi.scale=Vector3(1.8,1.8,1.8)
	if r>=2:
		var aura=AURA.instantiate(); aura.color=cl[r]
		if r>=3: aura.amount=12; aura.scale=Vector3(1.4,1.4,1.4)
		add_child(aura)
	# Pickup sphere - duzy promien zeby gracz mogl zbierac bez wchodzenia w mesh
	var cs:CollisionShape3D=$CollisionShape3D
	var sphere:=SphereShape3D.new(); sphere.radius=1.0+(r*0.15); cs.shape=sphere
	var nl=get_node_or_null("NameLabel")
	if nl: nl.text=data.get("name",""); nl.modulate=cl[r]; nl.visible=(r>=2)
func _process(delta:float)->void:
	if _collected: return
	_bob+=delta; position.y=_iy+0.35+sin(_bob*2)*0.08
	if scrap_data.get("rarity",0)>=3: rotation.y+=delta*1.5
	elif scrap_data.get("rarity",0)>=2: rotation.y+=delta*0.5
func collect()->void:
	if _collected or not is_inside_tree() or is_queued_for_deletion(): return
	_collected=true
	var pos:=global_position
	var val:int=scrap_data.get("value",1)*GameManager.click_power
	for i in GameManager.click_power:
		if GameManager.inventory.size()<GameManager.max_slots: GameManager.add_to_inventory(scrap_data.duplicate())
	AudioManager.play_collect_typed(scrap_data.get("id", ""))
	var r:int=scrap_data.get("rarity",0)
	var cl:Array=[Color("#888"),Color("#ff6a00"),Color("#00e5ff"),Color("#FFD700")]
	if r>=2:
		var cam=get_tree().current_scene.get_node_or_null("Camera3D")
		if cam and cam.has_method("shake"): cam.shake(0.15 if r<3 else 0.5,5.0)
	var sp=SPARKS.instantiate(); sp.position=pos; sp.color=cl[r]
	get_tree().current_scene.add_child(sp)
	sp.emitting=true
	get_tree().create_timer(1.0).timeout.connect(sp.queue_free)
	var pp=POPUP.instantiate(); pp.position=pos+Vector3(0,1,0); pp.setup(val,cl[r])
	get_tree().current_scene.add_child(pp); queue_free()

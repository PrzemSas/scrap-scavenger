extends Node3D
const SCRAP_SCENE=preload("res://scenes/objects/ScrapItem.tscn")
const WORLD_HALF:=44.0
const MAX_ITEMS:=65
var scrap_types:Array=[
	{"id":"can","name":"Aluminum Can","value":1,"rarity":0,"weight":35},
	{"id":"bolt","name":"Bolt","value":1,"rarity":0,"weight":25},
	{"id":"pipe","name":"Steel Pipe","value":3,"rarity":0,"weight":15},
	{"id":"cable","name":"Copper Cable","value":5,"rarity":1,"weight":12},
	{"id":"battery","name":"Battery","value":8,"rarity":1,"weight":8},
	{"id":"chip","name":"CPU Chip","value":12,"rarity":1,"weight":6},
	{"id":"coil","name":"Copper Coil","value":7,"rarity":1,"weight":9},
	{"id":"motor","name":"Motor","value":15,"rarity":2,"weight":4},
	{"id":"gear","name":"Titanium Gear","value":25,"rarity":2,"weight":3},
	{"id":"gold","name":"Gold Part","value":50,"rarity":3,"weight":1},
	{"id":"crystal","name":"Forge Crystal","value":100,"rarity":3,"weight":0.5},
]
var _rt:float=0.0
var _ev_active:bool=false
var _ev_timer:float=0.0
var _ev_bonus:float=1.0
func _ready()->void:
	for i in MAX_ITEMS: spawn_random()
func _process(delta:float)->void:
	var ws=get_node_or_null("/root/WeatherSystem")
	var spawn_mult:float=ws.get_spawn_mult() if ws else 1.0
	var max_now:int=int(MAX_ITEMS*spawn_mult)
	if get_child_count()<max_now:
		_rt+=delta
		if _rt>=0.8: _rt=0.0; spawn_random()
	if _ev_active:
		_ev_timer-=delta
		if _ev_timer<=0: _ev_active=false; _ev_bonus=1.0; GameManager.notification.emit("Event ended!")
func start_event(bonus:float,dur:float,msg:String)->void:
	_ev_active=true; _ev_bonus=bonus; _ev_timer=dur; GameManager.notification.emit(msg)
func _in_forge_zone(p:Vector3)->bool:
	return abs(p.x)<9.5 and abs(p.z)<9.5
func spawn_random()->void:
	var d=_roll_scrap()
	var item=SCRAP_SCENE.instantiate()
	var pos:=Vector3.ZERO
	for _i in 30:
		pos=Vector3(randf_range(-WORLD_HALF,WORLD_HALF),0,randf_range(-WORLD_HALF,WORLD_HALF))
		if not _in_forge_zone(pos): break
	item.position=pos
	add_child(item); item.setup(d)
func _roll_scrap()->Dictionary:
	var total:float=0.0
	for s in scrap_types: total+=s.weight
	var roll:float=randf()*total; var cum:float=0.0; var picked=scrap_types[0]
	for s in scrap_types:
		cum+=s.weight
		if roll<=cum: picked=s; break
	var luck:float=GameManager.luck_bonus
	if _ev_active: luck+=(_ev_bonus-1.0)*0.1
	if randf()<luck and picked.rarity<3:
		for s in scrap_types:
			if s.rarity==picked.rarity+1: picked=s; break
	var result=picked.duplicate()
	var ws=get_node_or_null("/root/WeatherSystem")
	var val_mult:float=ws.get_value_mult() if ws else 1.0
	if _ev_active: val_mult*=_ev_bonus
	result["value"]=int(result["value"]*val_mult)
	return result

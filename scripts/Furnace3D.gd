extends Node3D
var _active:bool=false
var _t:float=0.0
func _ready()->void:
	GameManager.sorted_changed.connect(_ck); GameManager.ingots_changed.connect(_ck)
	GameManager.smelt_queue_changed.connect(_on_queue_changed)
func _ck()->void:
	_active=GameManager.sorted_materials.size()>0 or GameManager.ingots.size()>0
func _process(delta:float)->void:
	_t+=delta
	var light=get_node_or_null("FireLight")
	var smoke=get_node_or_null("SmokePuff")
	if _active:
		if light: light.light_energy=0.5+sin(_t*3)*0.3
		if smoke: smoke.emitting=true
	else:
		if light: light.light_energy=lerpf(light.light_energy,0.0,delta*2)
		if smoke: smoke.emitting=false
func _on_queue_changed(size:int)->void:
	var lbl=get_node_or_null("QueueLabel")
	if not lbl: return
	lbl.visible=size>0
	lbl.text="QUEUE %d/%d"%[size,GameManager.get_smelt_queue_max()]

extends Control
@onready var status_l:Label=$FurnacePanel/StatusLabel
@onready var bar:ProgressBar=$FurnacePanel/ProgressBar
@onready var queue_l:Label=$FurnacePanel/QueueLabel
@onready var load_list:VBoxContainer=$LoadPanel/Scroll/LoadList
@onready var ingot_list:VBoxContainer=$IngotPanel/Scroll/IngotList
@onready var sell_btn:Button=$IngotPanel/SellAllBtn
@onready var ingot_panel:PanelContainer=$IngotPanel
var _q:Array=[]; var _sm:Dictionary={}; var _st:float=0.0; var _sd:float=0.0; var _active:bool=false
func _ready()->void:
	GameManager.sorted_changed.connect(_rl); GameManager.ingots_changed.connect(_ri)
	sell_btn.pressed.connect(func(): GameManager.sell_all_ingots(); AudioManager.play_sell())
	_rl(); _ri()
func _process(delta:float)->void:
	if not _active:
		if _q.is_empty(): status_l.text="IDLE"; bar.value=0; return
		_sm=_q.pop_front(); _sd=GameManager.smelt_config.get(_sm.get("id",""),{"time":10}).time/(1.0+GameManager.smelt_speed_bonus); _st=0; _active=true; _uq()
		return
	_st+=delta; bar.value=(_st/_sd)*100; status_l.text="SMELTING: %s %d%%"%[_sm.get("name","?").to_upper(),int(_st/_sd*100)]
	if _st>=_sd:
		_active=false; var cfg=GameManager.smelt_config.get(_sm.get("id",""),{"mult":2,"ingot":"Ingot"})
		GameManager.add_ingot({"name":cfg.ingot,"value":int(_sm.get("sorted_value",_sm.get("value",1))*cfg.mult),"source":_sm.get("name","?")})
		AudioManager.play_smelt_done(); _uq()
func _uq()->void: queue_l.text="QUEUE: %d/3"%_q.size()
func load_mat(idx:int)->void:
	if _q.size()>=3: return
	if idx<0 or idx>=GameManager.sorted_materials.size(): return
	_q.append(GameManager.sorted_materials[idx]); GameManager.sorted_materials.remove_at(idx); GameManager.sorted_changed.emit(); _uq()
func _rl()->void:
	for c in load_list.get_children(): c.queue_free()
	for i in GameManager.sorted_materials.size():
		var it=GameManager.sorted_materials[i]; var b=Button.new()
		b.text="%s %dc → LOAD"%[it.get("name","?"),it.get("sorted_value",0)]
		b.add_theme_color_override("font_color",Color("#ff6a00")); b.add_theme_font_size_override("font_size",10)
		var idx=i; b.pressed.connect(func(): load_mat(idx)); load_list.add_child(b)
func _ri()->void:
	for c in ingot_list.get_children(): c.queue_free()
	ingot_panel.visible=GameManager.ingots.size()>0; var t=0
	for i in GameManager.ingots.size():
		var ig=GameManager.ingots[i]; t+=ig.get("value",0); var b=Button.new()
		b.text="%s %dc"%[ig.get("name","?"),ig.get("value",0)]
		b.add_theme_color_override("font_color",Color("#FFD700")); b.add_theme_font_size_override("font_size",10)
		var idx=i; b.pressed.connect(func(): GameManager.sell_ingot(idx); AudioManager.play_sell())
		ingot_list.add_child(b)
	sell_btn.text="SELL ALL (%dc)"%t

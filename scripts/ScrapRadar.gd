extends Control
@onready var arrow:Label=$Arrow
@onready var info:Label=$Info
var _active:bool=false
func _ready()->void:
	visible=false
	GameManager.upgrade_purchased.connect(func(_id): _active=GameManager.upgrades.get("lucky_find",0)>=3; visible=_active)
func _process(_d:float)->void:
	if not _active: return
	var sm=get_tree().current_scene.get_node_or_null("SpawnManager")
	if not sm: return
	var best=null; var best_r:int=-1
	for ch in sm.get_children():
		if ch is Area3D and "scrap_data" in ch:
			var r:int=ch.scrap_data.get("rarity",0)
			if r>=2 and r>best_r: best_r=r; best=ch
	if best==null: info.text="No rare"; arrow.text="—"; return
	var cam=get_tree().current_scene.get_node_or_null("Camera3D")
	if not cam: return
	var dir=best.global_position-cam.global_position; dir.y=0
	var a=atan2(dir.x,dir.z)
	var arrows=["↑","↗","→","↘","↓","↙","←","↖"]
	var idx=int(round(a/(PI/4)))%8
	if idx<0: idx+=8
	arrow.text=arrows[idx]; info.text="%s %.0fm"%[["","","RARE","LEGEND"][best_r],dir.length()]
	var colors=[Color.WHITE,Color.WHITE,Color("#00e5ff"),Color("#FFD700")]
	arrow.add_theme_color_override("font_color",colors[best_r])

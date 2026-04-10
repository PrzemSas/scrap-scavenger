extends Control
@onready var ulist:VBoxContainer=$HSplit/LeftPanel/Scroll/UnsortedList
@onready var bins:GridContainer=$HSplit/RightPanel/BinGrid
@onready var stats_l:Label=$StatsBar
@onready var slist:VBoxContainer=$SortedPanel/Scroll/SortedList
@onready var spanel:PanelContainer=$SortedPanel
var _sel:int=-1
func _ready()->void:
	GameManager.inventory_changed.connect(_ref); GameManager.sorted_changed.connect(_refs)
	_build_bins(); _ref(); _refs()
func _ref()->void:
	for c in ulist.get_children(): c.queue_free()
	for i in GameManager.inventory.size():
		var it=GameManager.inventory[i]; var b=Button.new()
		b.text="%s (%dc)"%[it.get("name","?"),it.get("value",0)]
		b.add_theme_color_override("font_color",[Color("#888"),Color("#ff6a00"),Color("#00e5ff"),Color("#FFD700")][it.get("rarity",0)])
		b.add_theme_font_size_override("font_size",11); b.custom_minimum_size=Vector2(0,28)
		var idx=i; b.pressed.connect(func(): _sel=idx; _ref())
		if _sel==i: b.add_theme_color_override("font_color",Color.WHITE)
		ulist.add_child(b)
	stats_l.text="STREAK: %d | ACC: %d%%"%[GameManager.streak,GameManager.get_accuracy()]
func _build_bins()->void:
	for bd in [{"id":"ferrous","name":"FERROUS\n(Bolt,Pipe)","c":Color("#8899aa")},{"id":"electronics","name":"ELECTRO\n(Bat,Motor,Chip)","c":Color("#00e5ff")},{"id":"non_ferrous","name":"NON-FE\n(Can,Cable,Coil)","c":Color("#FF8A65")},{"id":"mechanical","name":"MECH\n(Gear)","c":Color("#88cc88")},{"id":"precious","name":"PRECIOUS\n(Gold,Crystal)","c":Color("#FFD700")}]:
		var b=Button.new(); b.text=bd.name; b.custom_minimum_size=Vector2(100,65)
		b.add_theme_color_override("font_color",bd.c); b.add_theme_font_size_override("font_size",10)
		var bid=bd.id; b.pressed.connect(func(): _sort(bid)); bins.add_child(b)
func _sort(bid:String)->void:
	if _sel<0 or _sel>=GameManager.inventory.size(): GameManager.notification.emit("Select item!"); return
	if GameManager.try_sort(_sel,bid): AudioManager.play_sort_correct()
	else: AudioManager.play_sort_wrong()
	_sel=-1; _ref()
func _refs()->void:
	for c in slist.get_children(): c.queue_free()
	spanel.visible=GameManager.sorted_materials.size()>0
	for i in GameManager.sorted_materials.size():
		var it=GameManager.sorted_materials[i]; var b=Button.new()
		b.text="%s — %dc"%[it.get("name","?"),it.get("sorted_value",0)]
		b.add_theme_color_override("font_color",Color("#39FF14")); b.add_theme_font_size_override("font_size",10)
		slist.add_child(b)

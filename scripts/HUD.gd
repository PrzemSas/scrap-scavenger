extends Control
@onready var coin_label:Label=$TopBar/CoinLabel
@onready var inv_label:Label=$TopBar/InvLabel
@onready var inv_panel:PanelContainer=$InventoryPanel
@onready var inv_grid:GridContainer=$InventoryPanel/ScrollContainer/InvGrid
@onready var sell_btn:Button=$InventoryPanel/SellAllBtn
@onready var shop_panel:PanelContainer=$ShopPanel
@onready var shop_list:VBoxContainer=$ShopPanel/ScrollContainer/ShopList
@onready var sort_panel:Control=$SortingTable
@onready var furnace_panel:Control=$Furnace
@onready var stats_panel:PanelContainer=$StatsPanel
@onready var stats_text:RichTextLabel=$StatsPanel/StatsText
@onready var prestige_btn:Button=$StatsPanel/PrestigeBtn
@onready var forge_panel:PanelContainer=$ForgeShopPanel
@onready var forge_list:VBoxContainer=$ForgeShopPanel/ScrollContainer/ForgeList
@onready var craft_panel:PanelContainer=$CraftPanel
@onready var craft_list:VBoxContainer=$CraftPanel/ScrollContainer/CraftList
@onready var leaderboard_panel:PanelContainer=$LeaderboardPanel
@onready var lb_list:VBoxContainer=$LeaderboardPanel/ScrollContainer/LBList
@onready var daily_panel:Control=$DailyRewardPanel
@onready var notif_label:Label=$NotifLabel
@onready var sell_panel:PanelContainer=$SellPanel
@onready var sell_list:VBoxContainer=$SellPanel/ScrollContainer/SellList
@onready var pile_hint:Label=$PileHintLabel
@onready var search_bar:Control=$SearchBar
@onready var search_progress:ProgressBar=$SearchBar/SearchProgress
var _nt:float=0.0
var _panels:Array=[]
var _proximity_panel:String=""
func _ready()->void:
	_panels=[inv_panel,shop_panel,sort_panel,furnace_panel,stats_panel,forge_panel,craft_panel,leaderboard_panel,sell_panel]
	GameManager.coins_changed.connect(func(c): coin_label.text="%d SC"%c; _shop())
	GameManager.inventory_changed.connect(func(): inv_label.text="INV %d/%d"%[GameManager.inventory.size(),GameManager.max_slots]; _inv())
	GameManager.upgrade_purchased.connect(func(_x): _shop())
	GameManager.notification.connect(func(m): notif_label.text=m; notif_label.visible=true; _nt=3.0)
	GameManager.prestige_done.connect(func(_x): _shop())
	GameManager.ingots_changed.connect(func(): _craft(); _sell())
	GameManager.inventory_changed.connect(func(): _sell())
	GameManager.proximity_entered.connect(_on_proximity_enter)
	GameManager.proximity_exited.connect(_on_proximity_exit)
	sell_btn.visible=false
	prestige_btn.pressed.connect(func(): GameManager.do_prestige(); AudioManager.play_prestige(); _stats())
	$TopBar/BtnInv.pressed.connect(func(): _toggle(inv_panel))
	$TopBar/BtnSort.pressed.connect(func(): _toggle(sort_panel))
	$TopBar/BtnForge.pressed.connect(func(): _toggle(furnace_panel))
	$TopBar/BtnShop.pressed.connect(func(): _toggle(shop_panel))
	$TopBar/BtnTokens.pressed.connect(func(): _toggle(forge_panel); _fshop())
	$TopBar/BtnStats.pressed.connect(func(): _toggle(stats_panel); _stats())
	$TopBar/BtnCraft.pressed.connect(func(): _toggle(craft_panel); _craft())
	$TopBar/BtnDaily.pressed.connect(func(): daily_panel.show_panel())
	$TopBar/BtnLeaderboard.pressed.connect(func(): _toggle(leaderboard_panel); _leaderboard())
	GameManager.pile_search_progress.connect(_on_search_progress)
	GameManager.pile_hint_changed.connect(_on_pile_hint)
	for p in _panels: p.visible=false
	notif_label.visible=false
	search_bar.visible=false
	pile_hint.visible=false
	coin_label.text="%d SC"%GameManager.coins
	inv_label.text="INV %d/%d"%[GameManager.inventory.size(),GameManager.max_slots]
	_shop()
func _on_proximity_enter(pid:String)->void:
	_proximity_panel=pid
	for p in _panels: p.visible=false
	match pid:
		"sort": sort_panel.visible=true; _sort_hint()
		"furnace": furnace_panel.visible=true
		"sell": sell_panel.visible=true; _sell()
		"shop": shop_panel.visible=true; _shop()
func _on_proximity_exit(pid:String)->void:
	if _proximity_panel!=pid: return
	_proximity_panel=""
	match pid:
		"sort": sort_panel.visible=false
		"furnace": furnace_panel.visible=false
		"sell": sell_panel.visible=false
		"shop": shop_panel.visible=false
func _sort_hint()->void:
	GameManager.notification.emit("Sorting table — drag items to bins")
func _process(delta:float)->void:
	if notif_label.visible:
		_nt-=delta
		if _nt<=0: notif_label.visible=false
func _toggle(panel:Control)->void:
	var was=panel.visible
	for p in _panels: p.visible=false
	panel.visible=not was
const ICON_CHARS:Dictionary={"can":"CAN","bolt":"BOLT","pipe":"PIPE","cable":"CBL","battery":"BAT","chip":"CHIP","coil":"COIL","motor":"MOT","gear":"GEAR","gold":"GOLD","crystal":"XTAL"}
func _get_icon(id:String)->Texture2D:
	var si=get_node_or_null("/root/ScrapIcons")
	if si: return si.get_icon(id)
	return null
func _inv()->void:
	for c in inv_grid.get_children(): c.queue_free()
	for i in GameManager.max_slots:
		var b=Button.new(); b.custom_minimum_size=Vector2(56,56)
		if i<GameManager.inventory.size():
			var it=GameManager.inventory[i]; var r=it.get("rarity",0)
			var id=it.get("id",""); var cl=[Color("#888"),Color("#ff6a00"),Color("#00e5ff"),Color("#FFD700")][r]
			var icon=_get_icon(id)
			if icon:
				b.icon=icon; b.text=""; b.add_theme_constant_override("icon_max_width",40)
			else:
				b.text=ICON_CHARS.get(id,id.substr(0,3).to_upper())
				b.add_theme_font_size_override("font_size",10)
			b.add_theme_color_override("font_color",cl)
			b.add_theme_stylebox_override("normal",_slot_style(cl,0.15))
			b.add_theme_stylebox_override("hover",_slot_style(cl,0.3))
			b.tooltip_text="%s\n%dc | %s"%[it.get("name","?"),it.get("value",0),["common","uncommon","rare","legendary"][r]]
		else:
			b.text=""; b.disabled=true
			b.add_theme_stylebox_override("normal",_slot_style(Color(0.15,0.15,0.15),0.1))
		inv_grid.add_child(b)
func _slot_style(c:Color,a:float)->StyleBoxFlat:
	var s=StyleBoxFlat.new(); s.bg_color=Color(c.r,c.g,c.b,a)
	s.border_color=Color(c.r,c.g,c.b,0.5); s.set_border_width_all(1)
	s.corner_radius_top_left=4; s.corner_radius_top_right=4
	s.corner_radius_bottom_left=4; s.corner_radius_bottom_right=4; return s
func _shop()->void:
	for c in shop_list.get_children(): c.queue_free()
	for uid in GameManager.upgrade_config:
		var cfg=GameManager.upgrade_config[uid]; var lv=GameManager.upgrades.get(uid,0)
		var mx=lv>=cfg.get("max",1); var cost=GameManager.get_upgrade_cost(uid); var can=not mx and GameManager.coins>=cost
		var h=HBoxContainer.new(); h.custom_minimum_size=Vector2(0,34)
		var info=VBoxContainer.new(); info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var nl=Label.new(); nl.text=uid.replace("_"," ").to_upper()
		nl.add_theme_color_override("font_color",Color("#39FF14") if mx else Color("#ff6a00")); nl.add_theme_font_size_override("font_size",11)
		info.add_child(nl)
		var dl=Label.new(); dl.text="%s | %d/%d"%[cfg.desc,lv,cfg.get("max",1)]
		dl.add_theme_color_override("font_color",Color("#555")); dl.add_theme_font_size_override("font_size",9)
		info.add_child(dl); h.add_child(info)
		var btn=Button.new(); btn.text="MAX" if mx else "%dc"%cost; btn.disabled=mx or not can; btn.custom_minimum_size=Vector2(70,0)
		if can: var id=uid; btn.pressed.connect(func(): GameManager.buy_upgrade(id))
		h.add_child(btn); shop_list.add_child(h)
func _fshop()->void:
	for c in forge_list.get_children(): c.queue_free()
	var hl=Label.new(); hl.text="TOKENS: %d"%GameManager.forge_tokens; hl.add_theme_color_override("font_color",Color("#FFD700"))
	forge_list.add_child(hl)
	for fid in GameManager.forge_shop_config:
		var cfg=GameManager.forge_shop_config[fid]; var cur=GameManager.forge_purchases.get(fid,0)
		var mx=cur>=cfg.get("max",1); var cost=cfg.get("cost",1); var can=not mx and GameManager.forge_tokens>=cost
		var h=HBoxContainer.new(); h.custom_minimum_size=Vector2(0,30)
		var nl=Label.new(); nl.text=fid.replace("_"," ").to_upper()+" - "+cfg.desc
		nl.add_theme_color_override("font_color",Color("#FFD700") if not mx else Color("#39FF14")); nl.add_theme_font_size_override("font_size",10)
		nl.size_flags_horizontal=Control.SIZE_EXPAND_FILL; h.add_child(nl)
		var btn=Button.new(); btn.text="MAX" if mx else "%d🔥"%cost; btn.disabled=mx or not can; btn.custom_minimum_size=Vector2(60,0)
		if can: var id=fid; btn.pressed.connect(func(): GameManager.buy_forge_item(id); AudioManager.play_upgrade(); _fshop())
		h.add_child(btn); forge_list.add_child(h)
func _craft()->void:
	for c in craft_list.get_children(): c.queue_free()
	var cm=get_node_or_null("/root/CraftingManager")
	if not cm: return
	var title=Label.new(); title.text="INGOTS: %d | CRAFTED: %d"%[GameManager.ingots.size(),cm.crafted_items.size()]
	title.add_theme_color_override("font_color",Color("#ff6a00")); title.add_theme_font_size_override("font_size",11)
	craft_list.add_child(title)
	for recipe in cm.recipes:
		var can=cm.can_craft(recipe)
		var h=HBoxContainer.new(); h.custom_minimum_size=Vector2(0,34)
		var info=VBoxContainer.new(); info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var nl=Label.new(); nl.text=recipe.name
		nl.add_theme_color_override("font_color",Color("#FFD700") if can else Color("#555")); nl.add_theme_font_size_override("font_size",11)
		info.add_child(nl)
		var dl=Label.new(); dl.text="%s → %dc"%[recipe.desc,recipe.value]
		dl.add_theme_color_override("font_color",Color("#888") if can else Color("#333")); dl.add_theme_font_size_override("font_size",9)
		info.add_child(dl); h.add_child(info)
		var btn=Button.new(); btn.text="CRAFT" if can else "—"; btn.disabled=not can; btn.custom_minimum_size=Vector2(70,0)
		if can:
			var r=recipe; btn.pressed.connect(func(): cm.craft(r); _craft())
		h.add_child(btn); craft_list.add_child(h)
	if cm.crafted_items.size()>0:
		var sep=HSeparator.new(); craft_list.add_child(sep)
		var cl=Label.new(); cl.text="CRAFTED ITEMS:"; cl.add_theme_color_override("font_color",Color("#39FF14")); cl.add_theme_font_size_override("font_size",10)
		craft_list.add_child(cl)
		for i in cm.crafted_items.size():
			var item=cm.crafted_items[i]
			var b=Button.new(); b.text="%s — %dc (click=sell)"%[item.name,item.value]
			b.add_theme_color_override("font_color",Color("#FFD700")); b.add_theme_font_size_override("font_size",10)
			var idx=i; b.pressed.connect(func(): cm.sell_crafted(idx); _craft())
			craft_list.add_child(b)
func _leaderboard()->void:
	for c in lb_list.get_children(): c.queue_free()
	var lm=get_node_or_null("/root/LeaderboardManager")
	var rank_hdr=Label.new()
	rank_hdr.text="YOUR RANK: #%d"%( lm.get_current_rank() if lm else 999)
	rank_hdr.add_theme_color_override("font_color",Color("#FFD700")); rank_hdr.add_theme_font_size_override("font_size",12)
	lb_list.add_child(rank_hdr)
	if not lm or lm.entries.is_empty():
		var nl=Label.new(); nl.text="No entries yet.\nPrestige to appear on the board!"
		nl.add_theme_color_override("font_color",Color("#555")); nl.add_theme_font_size_override("font_size",10)
		lb_list.add_child(nl)
	else:
		var medals=["🥇","🥈","🥉"]
		for i in lm.entries.size():
			var e=lm.entries[i]
			var h=HBoxContainer.new(); h.custom_minimum_size=Vector2(0,22)
			var rl=Label.new()
			rl.text=(medals[i] if i<3 else " #%d"%[i+1])+" "
			rl.add_theme_font_size_override("font_size",11)
			rl.add_theme_color_override("font_color",Color("#FFD700") if i<3 else Color("#666"))
			h.add_child(rl)
			var il=Label.new()
			il.text="%s — %dc  (P%d)"%[e.get("name","?"),e.get("lifetime_coins",0),e.get("prestige_count",0)]
			il.add_theme_font_size_override("font_size",10)
			il.add_theme_color_override("font_color",Color("#ff6a00") if i==0 else Color("#888"))
			il.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			h.add_child(il); lb_list.add_child(h)
	lb_list.add_child(HSeparator.new())
	var sub=Button.new(); sub.text="SUBMIT CURRENT SESSION"; sub.add_theme_font_size_override("font_size",10)
	sub.pressed.connect(func():
		if lm:
			var r=lm.submit_score("SCRAPPER")
			GameManager.notification.emit("Submitted! Rank #%d"%r)
			_leaderboard())
	lb_list.add_child(sub)
func _stats()->void:
	var m=int(GameManager.play_time/60); var h=int(m/60.0); m=m%60
	var t="[color=#ff6a00]STATS[/color]\n"
	t+="Coins: [color=#FFD700]%d[/color] | Lifetime: [color=#FFD700]%d[/color]\n"%[GameManager.coins,GameManager.lifetime_coins]
	t+="Collected: %d | Sorted: %d (Acc: %d%%)\n"%[GameManager.total_collected,GameManager.total_sorted,GameManager.get_accuracy()]
	t+="Smelted: %d | Streak: %d | Time: %dh%dm\n"%[GameManager.total_smelted,GameManager.best_streak,h,m]
	t+="\n[color=#ff3300]PRESTIGE[/color]\nTokens: [color=#FFD700]%d[/color] | Count: %d | +%d%%\n"%[GameManager.forge_tokens,GameManager.prestige_count,GameManager.forge_tokens*10]
	if GameManager.can_prestige(): t+="[color=#39FF14]+%d tokens available[/color]\n"%GameManager.get_prestige_tokens()
	t+="\n[color=#FFD700]ACHIEVEMENTS %d/%d[/color]\n"%[GameManager.achievements_unlocked.size(),GameManager.achievements_config.size()]
	t+="[color=#888]Daily streak: %d | Best: %d[/color]\n"%[daily_panel.login_streak if daily_panel else 0,GameManager.best_daily_streak]
	for a in GameManager.achievements_config:
		t+=("[color=#39FF14]✓[/color] " if a.id in GameManager.achievements_unlocked else "[color=#333]○[/color] ")+a.name+"\n"
	stats_text.text=t
	prestige_btn.visible=GameManager.can_prestige()
func _sell()->void:
	if not is_instance_valid(sell_list): return
	for c in sell_list.get_children(): c.queue_free()
	if GameManager.inventory.is_empty() and GameManager.ingots.is_empty():
		var lbl=Label.new(); lbl.text="Nothing to sell"
		lbl.add_theme_color_override("font_color",Color("#555")); lbl.add_theme_font_size_override("font_size",11)
		sell_list.add_child(lbl); return
	if not GameManager.inventory.is_empty():
		var hdr=Label.new(); hdr.text="-- ZLOM --"
		hdr.add_theme_color_override("font_color",Color("#ff6a00")); hdr.add_theme_font_size_override("font_size",11)
		sell_list.add_child(hdr)
		for i in GameManager.inventory.size():
			var it=GameManager.inventory[i]
			var h=HBoxContainer.new()
			var lbl=Label.new(); lbl.text="%s — %dc"%[it.get("name","?"),it.get("value",1)]
			lbl.add_theme_color_override("font_color",Color("#ccc")); lbl.add_theme_font_size_override("font_size",10)
			lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL; h.add_child(lbl)
			var btn=Button.new(); btn.text="SELL"; btn.custom_minimum_size=Vector2(55,0)
			var idx=i; btn.pressed.connect(func(): GameManager.sell_item(idx); AudioManager.play_sell(); _sell())
			h.add_child(btn); sell_list.add_child(h)
		var sell_all=Button.new(); sell_all.text="SELL ALL (%dc)"%GameManager.inventory.reduce(func(a,b): return a+b.get("value",1),0)
		sell_all.add_theme_color_override("font_color",Color("#39FF14"))
		sell_all.pressed.connect(func(): GameManager.sell_all(); AudioManager.play_sell(); _sell())
		sell_list.add_child(sell_all)
	if not GameManager.ingots.is_empty():
		var hdr=Label.new(); hdr.text="-- INGOTY --"
		hdr.add_theme_color_override("font_color",Color("#FFD700")); hdr.add_theme_font_size_override("font_size",11)
		sell_list.add_child(hdr)
		for i in GameManager.ingots.size():
			var ig=GameManager.ingots[i]
			var h=HBoxContainer.new()
			var lbl=Label.new(); lbl.text="%s — %dc"%[ig.get("name","?"),ig.get("value",1)]
			lbl.add_theme_color_override("font_color",Color("#FFD700")); lbl.add_theme_font_size_override("font_size",10)
			lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL; h.add_child(lbl)
			var btn=Button.new(); btn.text="SELL"; btn.custom_minimum_size=Vector2(55,0)
			var idx=i; btn.pressed.connect(func(): GameManager.sell_ingot(idx); AudioManager.play_sell(); _sell())
			h.add_child(btn); sell_list.add_child(h)
		var sell_all=Button.new(); sell_all.text="SELL ALL INGOTS (%dc)"%GameManager.ingots.reduce(func(a,b): return a+b.get("value",1),0)
		sell_all.add_theme_color_override("font_color",Color("#FFD700"))
		sell_all.pressed.connect(func(): GameManager.sell_all_ingots(); AudioManager.play_sell(); _sell())
		sell_list.add_child(sell_all)

func _on_search_progress(progress:float)->void:
	if progress < 0.0:
		search_bar.visible=false
		return
	search_bar.visible=true
	search_progress.value=progress*100.0

func _on_pile_hint(text:String)->void:
	if text.is_empty():
		pile_hint.visible=false
	else:
		pile_hint.text=text
		pile_hint.visible=true

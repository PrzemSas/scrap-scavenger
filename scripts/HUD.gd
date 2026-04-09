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
@onready var notif_label:Label=$NotifLabel

var _nt:float=0.0
var _panels:Array=[]

func _ready()->void:
	_panels=[inv_panel,shop_panel,sort_panel,furnace_panel,stats_panel,forge_panel]
	GameManager.coins_changed.connect(func(c): coin_label.text="%d COINS"%c; _shop())
	GameManager.inventory_changed.connect(func(): inv_label.text="INV %d/%d"%[GameManager.inventory.size(),GameManager.max_slots]; _inv())
	GameManager.upgrade_purchased.connect(func(_x): _shop())
	GameManager.notification.connect(func(m): notif_label.text=m; notif_label.visible=true; _nt=3.0)
	GameManager.prestige_done.connect(func(_x): _shop())
	sell_btn.pressed.connect(func(): GameManager.sell_all(); AudioManager.play_sell())
	prestige_btn.pressed.connect(func(): GameManager.do_prestige(); AudioManager.play_prestige(); _stats())
	$TopBar/BtnInv.pressed.connect(func(): _toggle(inv_panel))
	$TopBar/BtnSort.pressed.connect(func(): _toggle(sort_panel))
	$TopBar/BtnForge.pressed.connect(func(): _toggle(furnace_panel))
	$TopBar/BtnShop.pressed.connect(func(): _toggle(shop_panel))
	$TopBar/BtnTokens.pressed.connect(func(): _toggle(forge_panel); _forge_shop())
	$TopBar/BtnStats.pressed.connect(func(): _toggle(stats_panel); _stats())
	for p in _panels: p.visible=false
	notif_label.visible=false
	coin_label.text="%d COINS"%GameManager.coins
	inv_label.text="INV %d/%d"%[GameManager.inventory.size(),GameManager.max_slots]
	_shop()

func _process(delta:float)->void:
	if notif_label.visible:
		_nt-=delta
		if _nt<=0: notif_label.visible=false

func _toggle(panel:Control)->void:
	var was=panel.visible
	for p in _panels: p.visible=false
	panel.visible=not was

func _inv()->void:
	for c in inv_grid.get_children(): c.queue_free()
	for i in GameManager.max_slots:
		var b=Button.new(); b.custom_minimum_size=Vector2(50,50)
		if i<GameManager.inventory.size():
			var it=GameManager.inventory[i]; var r=it.get("rarity",0)
			b.text=["□","◆","★","✦"][r]; b.tooltip_text="%s (%dc)"%[it.get("name","?"),it.get("value",0)]
			b.add_theme_color_override("font_color",[Color("#888"),Color("#ff6a00"),Color("#00e5ff"),Color("#FFD700")][r])
			b.add_theme_font_size_override("font_size",20)
			var idx=i; b.pressed.connect(func(): GameManager.sell_item(idx); AudioManager.play_sell())
		else: b.text=""; b.disabled=true
		inv_grid.add_child(b)

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

func _forge_shop()->void:
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
		if can: var id=fid; btn.pressed.connect(func(): GameManager.buy_forge_item(id); AudioManager.play_upgrade(); _forge_shop())
		h.add_child(btn); forge_list.add_child(h)

func _stats()->void:
	var m=int(GameManager.play_time/60); var h=m/60; m=m%60
	var t="[color=#ff6a00]STATS[/color]\n"
	t+="Coins: [color=#FFD700]%d[/color]\n"%GameManager.coins
	t+="Lifetime: [color=#FFD700]%d[/color]\n"%GameManager.lifetime_coins
	t+="Collected: %d | Sorted: %d (Acc: %d%%)\n"%[GameManager.total_collected,GameManager.total_sorted,GameManager.get_accuracy()]
	t+="Smelted: %d | Best streak: %d\n"%[GameManager.total_smelted,GameManager.best_streak]
	t+="Time: %dh %dm\n\n"%[h,m]
	t+="[color=#ff3300]PRESTIGE[/color]\nTokens: [color=#FFD700]%d[/color] | Count: %d | Bonus: +%d%%\n"%[GameManager.forge_tokens,GameManager.prestige_count,GameManager.forge_tokens*10]
	if GameManager.can_prestige(): t+="Meltdown: [color=#39FF14]+%d tokens[/color]\n"%GameManager.get_prestige_tokens()
	t+="\n[color=#FFD700]ACHIEVEMENTS %d/%d[/color]\n"%[GameManager.achievements_unlocked.size(),GameManager.achievements_config.size()]
	for a in GameManager.achievements_config:
		t+=("[color=#39FF14]✓[/color] " if a.id in GameManager.achievements_unlocked else "[color=#333]○[/color] ")+a.name+"\n"
	stats_text.text=t
	prestige_btn.visible=GameManager.can_prestige()
	prestige_btn.text="🔥 MELTDOWN +%d"%GameManager.get_prestige_tokens()

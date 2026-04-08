extends Control

@onready var coin_label: Label = $TopBar/CoinLabel
@onready var inv_label: Label = $TopBar/InvLabel
@onready var inv_grid: GridContainer = $InventoryPanel/ScrollContainer/InvGrid
@onready var sell_all_btn: Button = $InventoryPanel/SellAllBtn
@onready var inv_panel: PanelContainer = $InventoryPanel
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var shop_list: VBoxContainer = $ShopPanel/ScrollContainer/ShopList
@onready var sorting_table: Control = $SortingTable
@onready var furnace: Control = $Furnace
@onready var notif_label: Label = $NotifLabel
@onready var stats_panel: PanelContainer = $StatsPanel
@onready var stats_text: RichTextLabel = $StatsPanel/StatsText
@onready var prestige_btn: Button = $StatsPanel/PrestigeBtn
@onready var encyclopedia: Control = $Encyclopedia
@onready var forge_panel: PanelContainer = $ForgeShopPanel
@onready var forge_list: VBoxContainer = $ForgeShopPanel/ScrollContainer/ForgeList
@onready var tutorial_label: Label = $TutorialLabel

var _notif_timer: float = 0.0
var _tutorial_timer: float = 0.0

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.upgrade_purchased.connect(func(_x): _build_shop())
	GameManager.notification.connect(_show_notif)
	GameManager.prestige_done.connect(func(_x): _refresh_all())
	GameManager.tutorial_step.connect(_show_tutorial)
	sell_all_btn.pressed.connect(func(): GameManager.sell_all(); AudioManager.play_sell())
	prestige_btn.pressed.connect(_on_prestige)
	$TopBar/ToggleInvBtn.pressed.connect(func(): _show_panel("inv"))
	$TopBar/ToggleShopBtn.pressed.connect(func(): _show_panel("shop"))
	$TopBar/ToggleSortBtn.pressed.connect(func(): _show_panel("sort"))
	$TopBar/ToggleFurnaceBtn.pressed.connect(func(): _show_panel("furnace"))
	$TopBar/ToggleStatsBtn.pressed.connect(func(): _show_panel("stats"))
	$TopBar/ToggleEncBtn.pressed.connect(func(): _show_panel("enc"))
	$TopBar/ToggleForgeBtn.pressed.connect(func(): _show_panel("forge"))
	_refresh_all()
	_hide_all_panels()
	notif_label.visible = false
	tutorial_label.visible = false

func _process(delta: float) -> void:
	if notif_label.visible:
		_notif_timer -= delta
		if _notif_timer <= 0: notif_label.visible = false
	if tutorial_label.visible:
		_tutorial_timer -= delta
		if _tutorial_timer <= 0: tutorial_label.visible = false

func _refresh_all() -> void:
	_on_coins_changed(GameManager.coins)
	_on_inventory_changed()
	_build_shop()

func _show_notif(msg: String) -> void:
	notif_label.text = msg
	notif_label.visible = true
	_notif_timer = 3.0

func _show_tutorial(step: String) -> void:
	tutorial_label.text = "💡 " + step
	tutorial_label.visible = true
	_tutorial_timer = 6.0

func _hide_all_panels() -> void:
	inv_panel.visible = false
	shop_panel.visible = false
	sorting_table.visible = false
	furnace.visible = false
	stats_panel.visible = false
	forge_panel.visible = false
	encyclopedia.visible = false

func _show_panel(p: String) -> void:
	var was = false
	match p:
		"inv": was = inv_panel.visible
		"shop": was = shop_panel.visible
		"sort": was = sorting_table.visible
		"furnace": was = furnace.visible
		"stats": was = stats_panel.visible
		"forge": was = forge_panel.visible
		"enc": was = encyclopedia.visible
	_hide_all_panels()
	if not was:
		match p:
			"inv": inv_panel.visible = true
			"shop": shop_panel.visible = true
			"sort": sorting_table.visible = true
			"furnace": furnace.visible = true
			"stats": stats_panel.visible = true; _refresh_stats()
			"forge": forge_panel.visible = true; _build_forge_shop()
			"enc": encyclopedia.visible = true; encyclopedia.show_encyclopedia()

func _on_coins_changed(amount: int) -> void:
	coin_label.text = "%d COINS" % amount

func _on_inventory_changed() -> void:
	inv_label.text = "INV %d/%d" % [GameManager.inventory.size(), GameManager.max_slots]
	_build_inventory_grid()

func _refresh_stats() -> void:
	var mins = int(GameManager.play_time / 60)
	var hrs = mins / 60; mins = mins % 60
	var acc = GameManager.get_accuracy()
	var t = "[color=#ff6a00]STATISTICS[/color]\n\n"
	t += "Coins: [color=#FFD700]%d[/color]\n" % GameManager.coins
	t += "Lifetime: [color=#FFD700]%d[/color]\n" % GameManager.lifetime_coins
	t += "Collected: [color=#ff6a00]%d[/color]\n" % GameManager.total_collected
	t += "Sorted: [color=#ff6a00]%d[/color] (Acc: %d%%)\n" % [GameManager.total_sorted, acc]
	t += "Best streak: [color=#ff6a00]%d[/color]\n" % GameManager.best_streak
	t += "Smelted: [color=#ff6a00]%d[/color]\n" % GameManager.total_smelted
	t += "Time: [color=#888]%dh %dm[/color]\n" % [hrs, mins]
	t += "\n[color=#ff3300]PRESTIGE[/color]\n"
	t += "Forge Tokens: [color=#FFD700]%d[/color]\n" % GameManager.forge_tokens
	t += "Prestige: %d | Bonus: [color=#39FF14]+%d%%[/color]\n" % [GameManager.prestige_count, GameManager.forge_tokens * 10]
	if GameManager.can_prestige():
		t += "Meltdown: [color=#39FF14]+%d tokens[/color]\n" % GameManager.get_prestige_tokens()
	else:
		t += "Meltdown at 50K lifetime\n"
	t += "\n[color=#FFD700]ACHIEVEMENTS (%d/%d)[/color]\n" % [GameManager.achievements_unlocked.size(), GameManager.achievements_config.size()]
	for ach in GameManager.achievements_config:
		if ach.id in GameManager.achievements_unlocked:
			t += "[color=#39FF14]✓[/color] %s\n" % ach.name
		else:
			t += "[color=#333]○ %s[/color]\n" % ach.name
	stats_text.text = t
	prestige_btn.visible = GameManager.can_prestige()
	prestige_btn.text = "🔥 MELTDOWN (+%d tokens)" % GameManager.get_prestige_tokens()

func _on_prestige() -> void:
	GameManager.do_prestige()
	AudioManager.play_prestige()
	_refresh_stats()
	_build_shop()

func _build_forge_shop() -> void:
	for c in forge_list.get_children():
		c.queue_free()
	# Header
	var header = Label.new()
	header.text = "FORGE TOKENS: %d" % GameManager.forge_tokens
	header.add_theme_color_override("font_color", Color("#FFD700"))
	header.add_theme_font_size_override("font_size", 14)
	forge_list.add_child(header)
	var sep = HSeparator.new()
	forge_list.add_child(sep)
	for item_id in GameManager.forge_shop_config:
		var config = GameManager.forge_shop_config[item_id]
		var current = GameManager.forge_purchases.get(item_id, 0)
		var maxed = current >= config.get("max", 1)
		var cost = config.get("cost", 1)
		var can = not maxed and GameManager.forge_tokens >= cost
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 34)
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nl = Label.new()
		nl.text = item_id.replace("_", " ").to_upper()
		nl.add_theme_color_override("font_color", Color("#FFD700") if not maxed else Color("#39FF14"))
		nl.add_theme_font_size_override("font_size", 10)
		info.add_child(nl)
		var dl = Label.new()
		var type_str = "[%s]" % config.get("type", "?")
		dl.text = "%s %s | %d/%d" % [config.get("desc", ""), type_str, current, config.get("max", 1)]
		dl.add_theme_color_override("font_color", Color("#555"))
		dl.add_theme_font_size_override("font_size", 9)
		info.add_child(dl)
		hbox.add_child(info)
		var btn = Button.new()
		btn.text = "MAX" if maxed else "%d🔥" % cost
		btn.disabled = maxed or not can
		btn.custom_minimum_size = Vector2(60, 0)
		if can:
			var uid = item_id
			btn.pressed.connect(func():
				GameManager.buy_forge_item(uid)
				AudioManager.play_upgrade()
				_build_forge_shop()
			)
		hbox.add_child(btn)
		forge_list.add_child(hbox)

func _build_inventory_grid() -> void:
	for c in inv_grid.get_children():
		c.queue_free()
	for i in GameManager.max_slots:
		var slot = Button.new()
		slot.custom_minimum_size = Vector2(50, 50)
		if i < GameManager.inventory.size():
			var item = GameManager.inventory[i]
			var rarity = item.get("rarity", 0)
			var symbols = ["□", "◆", "★", "✦"]
			var colors = [Color("#888888"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]
			slot.text = symbols[rarity]
			slot.tooltip_text = "%s (%dc)" % [item.get("name", "?"), item.get("value", 0)]
			slot.add_theme_color_override("font_color", colors[rarity])
			slot.add_theme_font_size_override("font_size", 20)
			var idx = i
			slot.pressed.connect(func(): GameManager.sell_item(idx); AudioManager.play_sell())
		else:
			slot.text = ""; slot.disabled = true
		var s = StyleBoxFlat.new()
		s.bg_color = Color("#1a1a1a"); s.border_color = Color("#333")
		s.set_border_width_all(1); s.set_corner_radius_all(4)
		slot.add_theme_stylebox_override("normal", s)
		inv_grid.add_child(slot)

func _build_shop() -> void:
	for c in shop_list.get_children():
		c.queue_free()
	for uid in GameManager.upgrade_config:
		var config = GameManager.upgrade_config[uid]
		var level = GameManager.upgrades.get(uid, 0)
		var max_lvl = config.get("max", 1)
		var cost = GameManager.get_upgrade_cost(uid)
		var maxed = level >= max_lvl
		var can = not maxed and GameManager.coins >= cost
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 36)
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nl = Label.new()
		nl.text = uid.replace("_", " ").to_upper()
		nl.add_theme_color_override("font_color", Color("#ff6a00") if not maxed else Color("#39FF14"))
		nl.add_theme_font_size_override("font_size", 11)
		info.add_child(nl)
		var dl = Label.new()
		dl.text = "%s | Lvl %d/%d" % [config.desc, level, max_lvl]
		dl.add_theme_color_override("font_color", Color("#555"))
		dl.add_theme_font_size_override("font_size", 9)
		info.add_child(dl)
		hbox.add_child(info)
		var btn = Button.new()
		btn.text = "MAX" if maxed else "%dc" % cost
		btn.disabled = maxed or not can
		btn.custom_minimum_size = Vector2(70, 0)
		if can:
			var id = uid
			btn.pressed.connect(func(): GameManager.buy_upgrade(id))
		hbox.add_child(btn)
		shop_list.add_child(hbox)

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

var _notif_timer: float = 0.0

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.upgrade_purchased.connect(_on_upgrade_purchased)
	GameManager.notification.connect(_show_notif)
	sell_all_btn.pressed.connect(func(): GameManager.sell_all())
	$TopBar/ToggleInvBtn.pressed.connect(func(): _show_panel("inv"))
	$TopBar/ToggleShopBtn.pressed.connect(func(): _show_panel("shop"))
	$TopBar/ToggleSortBtn.pressed.connect(func(): _show_panel("sort"))
	$TopBar/ToggleFurnaceBtn.pressed.connect(func(): _show_panel("furnace"))
	_on_coins_changed(GameManager.coins)
	_on_inventory_changed()
	_build_shop()
	_hide_all_panels()
	notif_label.visible = false

func _process(delta: float) -> void:
	if notif_label.visible:
		_notif_timer -= delta
		if _notif_timer <= 0:
			notif_label.visible = false

func _show_notif(msg: String) -> void:
	notif_label.text = msg
	notif_label.visible = true
	_notif_timer = 2.0

func _hide_all_panels() -> void:
	inv_panel.visible = false
	shop_panel.visible = false
	sorting_table.visible = false
	furnace.visible = false

func _show_panel(panel_name: String) -> void:
	var was_visible = false
	match panel_name:
		"inv": was_visible = inv_panel.visible
		"shop": was_visible = shop_panel.visible
		"sort": was_visible = sorting_table.visible
		"furnace": was_visible = furnace.visible
	_hide_all_panels()
	if not was_visible:
		match panel_name:
			"inv": inv_panel.visible = true
			"shop": shop_panel.visible = true
			"sort": sorting_table.visible = true
			"furnace": furnace.visible = true

func _on_coins_changed(amount: int) -> void:
	coin_label.text = "%d COINS" % amount
	_build_shop()

func _on_inventory_changed() -> void:
	inv_label.text = "INV %d/%d" % [GameManager.inventory.size(), GameManager.max_slots]
	_build_inventory_grid()

func _on_upgrade_purchased(_id: String) -> void:
	_build_shop()

func _build_inventory_grid() -> void:
	for child in inv_grid.get_children():
		child.queue_free()
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
			slot.pressed.connect(func(): GameManager.sell_item(idx))
		else:
			slot.text = ""
			slot.disabled = true
		slot.add_theme_stylebox_override("normal", _slot_style(false))
		slot.add_theme_stylebox_override("hover", _slot_style(true))
		inv_grid.add_child(slot)

func _slot_style(hover: bool) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color("#1a1a1a") if not hover else Color("#2a1500")
	s.border_color = Color("#333333") if not hover else Color("#ff6a00")
	s.set_border_width_all(1)
	s.set_corner_radius_all(4)
	return s

func _build_shop() -> void:
	for child in shop_list.get_children():
		child.queue_free()
	for upgrade_id in GameManager.upgrade_config:
		var config = GameManager.upgrade_config[upgrade_id]
		var level = GameManager.upgrades.get(upgrade_id, 0)
		var max_lvl = config.get("max", 1)
		var cost = GameManager.get_upgrade_cost(upgrade_id)
		var maxed = level >= max_lvl
		var can_buy = not maxed and GameManager.coins >= cost
		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 40)
		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_label = Label.new()
		name_label.text = upgrade_id.replace("_", " ").to_upper()
		name_label.add_theme_color_override("font_color", Color("#ff6a00") if not maxed else Color("#39FF14"))
		name_label.add_theme_font_size_override("font_size", 12)
		info.add_child(name_label)
		var desc_label = Label.new()
		desc_label.text = "%s | Lvl %d/%d" % [config.get("desc", ""), level, max_lvl]
		desc_label.add_theme_color_override("font_color", Color("#666666"))
		desc_label.add_theme_font_size_override("font_size", 10)
		info.add_child(desc_label)
		hbox.add_child(info)
		var btn = Button.new()
		if maxed:
			btn.text = "MAX"
			btn.disabled = true
		else:
			btn.text = "%dc" % cost
			btn.disabled = not can_buy
			var uid = upgrade_id
			btn.pressed.connect(func(): GameManager.buy_upgrade(uid))
		btn.custom_minimum_size = Vector2(70, 0)
		hbox.add_child(btn)
		shop_list.add_child(hbox)

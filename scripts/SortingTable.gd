extends Control

signal sorting_done()

@onready var unsorted_list: VBoxContainer = $HSplit/LeftPanel/Scroll/UnsortedList
@onready var bin_grid: GridContainer = $HSplit/RightPanel/BinGrid
@onready var stats_label: Label = $StatsBar
@onready var sorted_list: VBoxContainer = $SortedPanel/Scroll/SortedList
@onready var sorted_panel: PanelContainer = $SortedPanel

var _selected_index: int = -1

func _ready() -> void:
	GameManager.inventory_changed.connect(_refresh)
	GameManager.sorted_changed.connect(_refresh_sorted)
	_build_bins()
	_refresh()
	_refresh_sorted()

func _refresh() -> void:
	for c in unsorted_list.get_children():
		c.queue_free()
	for i in GameManager.inventory.size():
		var item = GameManager.inventory[i]
		var btn = Button.new()
		var rarity = item.get("rarity", 0)
		var colors = [Color("#888888"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]
		btn.text = "%s (%dc)" % [item.get("name", "?"), item.get("value", 0)]
		btn.add_theme_color_override("font_color", colors[rarity])
		btn.add_theme_font_size_override("font_size", 12)
		btn.custom_minimum_size = Vector2(0, 32)
		var idx = i
		btn.pressed.connect(func(): _select_item(idx))
		if _selected_index == i:
			btn.add_theme_color_override("font_color", Color.WHITE)
		unsorted_list.add_child(btn)
	_update_stats()

func _select_item(index: int) -> void:
	_selected_index = index
	_refresh()

func _build_bins() -> void:
	var bin_data = [
		{"id": "ferrous", "name": "FERROUS", "color": Color("#8899aa")},
		{"id": "electronics", "name": "ELECTRO", "color": Color("#00e5ff")},
		{"id": "non_ferrous", "name": "NON-FE", "color": Color("#FF8A65")},
		{"id": "precious", "name": "PRECIOUS", "color": Color("#FFD700")},
	]
	for b in bin_data:
		var btn = Button.new()
		btn.text = b.name
		btn.custom_minimum_size = Vector2(100, 80)
		btn.add_theme_color_override("font_color", b.color)
		btn.add_theme_font_size_override("font_size", 14)
		var bid = b.id
		btn.pressed.connect(func(): _sort_to_bin(bid))
		bin_grid.add_child(btn)

func _sort_to_bin(bin_id: String) -> void:
	if _selected_index < 0 or _selected_index >= GameManager.inventory.size():
		GameManager.notification.emit("Select an item first!")
		return
	var result = GameManager.try_sort(_selected_index, bin_id)
	_selected_index = -1
	_refresh()

func _refresh_sorted() -> void:
	for c in sorted_list.get_children():
		c.queue_free()
	sorted_panel.visible = GameManager.sorted_materials.size() > 0
	for i in GameManager.sorted_materials.size():
		var item = GameManager.sorted_materials[i]
		var btn = Button.new()
		btn.text = "%s — %dc" % [item.get("name", "?"), item.get("sorted_value", 0)]
		btn.add_theme_color_override("font_color", Color("#ff6a00"))
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(0, 28)
		btn.tooltip_text = "Click to load into furnace"
		unsorted_list.add_child(btn) # will be handled by furnace
		sorted_list.add_child(btn)

func _update_stats() -> void:
	var acc = 0
	if GameManager.total_sorted > 0:
		acc = int(float(GameManager.correct_sorted) / GameManager.total_sorted * 100)
	stats_label.text = "STREAK: %d | ACC: %d%% | SORTED: %d" % [GameManager.streak, acc, GameManager.total_sorted]

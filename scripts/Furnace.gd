extends Control

@onready var status_label: Label = $FurnacePanel/StatusLabel
@onready var progress_bar: ProgressBar = $FurnacePanel/ProgressBar
@onready var queue_label: Label = $FurnacePanel/QueueLabel
@onready var load_list: VBoxContainer = $LoadPanel/Scroll/LoadList
@onready var ingot_list: VBoxContainer = $IngotPanel/Scroll/IngotList
@onready var sell_all_btn: Button = $IngotPanel/SellAllBtn
@onready var ingot_panel: PanelContainer = $IngotPanel

var _queue: Array = []
var _smelting: Dictionary = {}
var _smelt_timer: float = 0.0
var _smelt_duration: float = 0.0
var _is_smelting: bool = false
const MAX_QUEUE: int = 3

func _ready() -> void:
	GameManager.sorted_changed.connect(_refresh_load)
	GameManager.ingots_changed.connect(_refresh_ingots)
	GameManager.upgrade_purchased.connect(_on_upgrade)
	sell_all_btn.pressed.connect(func():
		GameManager.sell_all_ingots()
		AudioManager.play_sell()
	)
	progress_bar.value = 0
	_refresh_load()
	_refresh_ingots()

func _on_upgrade(id: String) -> void:
	if id == "second_furnace":
		pass  # Could add second furnace logic here

func _process(delta: float) -> void:
	if not _is_smelting:
		_try_start()
		return
	_smelt_timer += delta
	var pct = _smelt_timer / _smelt_duration
	progress_bar.value = pct * 100.0
	status_label.text = "SMELTING: %s — %d%%" % [_smelting.get("name", "?").to_upper(), int(pct * 100)]
	if _smelt_timer >= _smelt_duration:
		_complete()

func _try_start() -> void:
	if _queue.is_empty():
		status_label.text = "IDLE — Load sorted materials"
		progress_bar.value = 0
		return
	_smelting = _queue.pop_front()
	var config = GameManager.smelt_config.get(_smelting.get("id", ""), {"time": 10.0, "mult": 2.0, "ingot": "Ingot"})
	_smelt_duration = config.time / (1.0 + GameManager.smelt_speed_bonus)
	_smelt_timer = 0.0
	_is_smelting = true
	_update_queue_label()

func _complete() -> void:
	_is_smelting = false
	var config = GameManager.smelt_config.get(_smelting.get("id", ""), {"time": 10.0, "mult": 2.0, "ingot": "Ingot"})
	var value = int(_smelting.get("sorted_value", _smelting.get("value", 1)) * config.mult)
	GameManager.add_ingot({
		"name": config.ingot,
		"value": value,
		"source": _smelting.get("name", "?"),
	})
	AudioManager.play_smelt_done()
	_smelting = {}
	progress_bar.value = 0
	status_label.text = "DONE! Ingot ready."
	_update_queue_label()

func load_material(sorted_index: int) -> void:
	if _queue.size() >= _get_max_queue():
		GameManager.notification.emit("Furnace queue full!")
		return
	if sorted_index < 0 or sorted_index >= GameManager.sorted_materials.size():
		return
	var item = GameManager.sorted_materials[sorted_index]
	_queue.append(item)
	GameManager.sorted_materials.remove_at(sorted_index)
	GameManager.sorted_changed.emit()
	AudioManager.play_click()
	_update_queue_label()

func _get_max_queue() -> int:
	var bonus = GameManager.upgrades.get("second_furnace", 0) * 2
	return MAX_QUEUE + bonus

func _update_queue_label() -> void:
	queue_label.text = "QUEUE: %d/%d" % [_queue.size(), _get_max_queue()]

func _refresh_load() -> void:
	for c in load_list.get_children():
		c.queue_free()
	for i in GameManager.sorted_materials.size():
		var item = GameManager.sorted_materials[i]
		var config = GameManager.smelt_config.get(item.get("id", ""), {"mult": 2.0, "ingot": "?"})
		var est_value = int(item.get("sorted_value", item.get("value", 1)) * config.mult)
		var btn = Button.new()
		btn.text = "%s — %dc → %s (%dc)" % [item.get("name", "?"), item.get("sorted_value", 0), config.ingot, est_value]
		btn.add_theme_color_override("font_color", Color("#ff6a00"))
		btn.add_theme_font_size_override("font_size", 10)
		btn.custom_minimum_size = Vector2(0, 26)
		var idx = i
		btn.pressed.connect(func(): load_material(idx))
		load_list.add_child(btn)

func _refresh_ingots() -> void:
	for c in ingot_list.get_children():
		c.queue_free()
	ingot_panel.visible = GameManager.ingots.size() > 0
	var total = 0
	for i in GameManager.ingots.size():
		var ingot = GameManager.ingots[i]
		total += ingot.get("value", 0)
		var btn = Button.new()
		btn.text = "%s — %dc (from %s)" % [ingot.get("name", "?"), ingot.get("value", 0), ingot.get("source", "?")]
		btn.add_theme_color_override("font_color", Color("#FFD700"))
		btn.add_theme_font_size_override("font_size", 10)
		btn.custom_minimum_size = Vector2(0, 26)
		var idx = i
		btn.pressed.connect(func():
			GameManager.sell_ingot(idx)
			AudioManager.play_sell()
		)
		ingot_list.add_child(btn)
	sell_all_btn.text = "SELL ALL (%dc)" % total

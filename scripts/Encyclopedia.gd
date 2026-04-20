extends Control

@onready var text_display: RichTextLabel = $Panel/Scroll/Content

var discovered: Dictionary = {}

func _ready() -> void:
	visible = false
	_load_discovered()
	GameManager.inventory_changed.connect(_check_new)

func _check_new() -> void:
	for item in GameManager.inventory:
		var id = item.get("id", "")
		if id != "" and id not in discovered:
			discovered[id] = {
				"name": item.get("name", "?"),
				"value": item.get("value", 0),
				"rarity": item.get("rarity", 0),
				"first_found": GameManager.play_time,
			}
			_save_discovered()

func show_encyclopedia() -> void:
	visible = true
	_build_display()

func hide_encyclopedia() -> void:
	visible = false

func _build_display() -> void:
	var rarity_names = ["Common", "Uncommon", "Rare", "Legendary"]
	var rarity_colors = ["#888888", "#ff6a00", "#00e5ff", "#FFD700"]
	var all_types = ["can", "bolt", "pipe", "cable", "battery", "motor", "gold"]
	var _all_names = {
		"can": "Aluminum Can", "bolt": "Bolt", "pipe": "Steel Pipe",
		"cable": "Copper Cable", "battery": "Battery", "motor": "Motor", "gold": "Gold Part"
	}
	var t = "[color=#ff6a00]SCRAP ENCYCLOPEDIA[/color]\n"
	t += "Discovered: %d / %d\n\n" % [discovered.size(), all_types.size()]
	for id in all_types:
		if id in discovered:
			var d = discovered[id]
			var r = d.get("rarity", 0)
			var rc = rarity_colors[r]
			t += "[color=%s]✓ %s[/color]\n" % [rc, d.name]
			t += "  Value: %dc | %s\n" % [d.value, rarity_names[r]]
			var mins = int(d.get("first_found", 0) / 60)
			t += "  [color=#333]Found at %d min[/color]\n\n" % mins
		else:
			t += "[color=#222]? ? ? ? ?[/color]\n"
			t += "  [color=#111]Not yet discovered[/color]\n\n"
	text_display.text = t

func _save_discovered() -> void:
	var f = FileAccess.open("user://encyclopedia.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(discovered))

func _load_discovered() -> void:
	if not FileAccess.file_exists("user://encyclopedia.json"):
		return
	var f = FileAccess.open("user://encyclopedia.json", FileAccess.READ)
	if not f:
		return
	var json = JSON.new()
	if json.parse(f.get_as_text()) == OK:
		discovered = json.data

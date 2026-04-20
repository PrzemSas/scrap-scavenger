extends Control

const DONE_PATH := "user://tutorial_done.flag"

const STEPS := [
	{
		"text": "[color=#ff6a00]Welcome to Scrap Scavenger![/color]\n\nWalk around the junkyard and press [color=#FFD700][E][/color] near scrap to collect it.\nYour goal: collect → sort → smelt → sell.",
		"trigger": "collect"
	},
	{
		"text": "Nice! You collected your first scrap.\n\nOpen the [color=#ff6a00]Sorting Table[/color] with [color=#FFD700][2][/color] or the [color=#ff6a00]♻[/color] button,\nthen drag items into the correct bins.",
		"trigger": "manual"
	},
	{
		"text": "After sorting, open the [color=#ff6a00]Furnace[/color] with [color=#FFD700][3][/color] or [color=#ff6a00]🔥[/color]\nto smelt sorted materials into valuable ingots.",
		"trigger": "manual"
	},
	{
		"text": "Sell scrap, ingots and crafted items at the [color=#39FF14]Sell Point[/color]\nor press [color=#FFD700][4][/color] to open the [color=#ff6a00]Shop[/color] and buy upgrades.",
		"trigger": "manual"
	},
	{
		"text": "[color=#FFD700]Keys 1–9[/color] open all panels. [color=#FFD700]Escape[/color] closes them.\n\nPrestige when ready to reset with bonus tokens.\n[color=#39FF14]Good luck, Scrapper![/color]",
		"trigger": "manual"
	},
]

var _step: int = 0

@onready var _panel: PanelContainer = $Panel
@onready var _text: RichTextLabel = $Panel/VBox/Text
@onready var _next_btn: Button = $Panel/VBox/Buttons/NextBtn
@onready var _skip_btn: Button = $Panel/VBox/Buttons/SkipBtn
@onready var _counter: Label = $Panel/VBox/Counter

func _ready() -> void:
	if FileAccess.file_exists(DONE_PATH):
		queue_free()
		return
	_show_step()
	GameManager.inventory_changed.connect(_on_inventory_changed)
	_next_btn.pressed.connect(_advance)
	_skip_btn.pressed.connect(_finish)

func _show_step() -> void:
	var s: Dictionary = STEPS[_step]
	_text.text = s["text"]
	_counter.text = "%d / %d" % [_step + 1, STEPS.size()]
	_next_btn.text = "Finish!" if _step == STEPS.size() - 1 else "Next ▶"
	_next_btn.visible = s["trigger"] == "manual" or _step == STEPS.size() - 1

func _on_inventory_changed() -> void:
	if _step < STEPS.size() and STEPS[_step]["trigger"] == "collect":
		if GameManager.inventory.size() >= 1:
			_advance()

func _advance() -> void:
	_step += 1
	if _step >= STEPS.size():
		_finish()
		return
	_show_step()

func _finish() -> void:
	var f := FileAccess.open(DONE_PATH, FileAccess.WRITE)
	if f:
		f.store_string("done")
	queue_free()

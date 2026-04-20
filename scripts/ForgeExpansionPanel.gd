extends Control

@onready var _title: Label = $Panel/VBox/Title
@onready var _stage_label: Label = $Panel/VBox/StageLabel
@onready var _req_list: VBoxContainer = $Panel/VBox/ReqList
@onready var _build_btn: Button = $Panel/VBox/BuildBtn
@onready var _done_label: Label = $Panel/VBox/DoneLabel

func _ready() -> void:
	visible = false
	GameManager.building_materials_changed.connect(_refresh)
	GameManager.forge_stage_changed.connect(func(_s: int): _refresh())
	_build_btn.pressed.connect(_on_build)
	_refresh()

func show_panel() -> void:
	visible = true
	_refresh()

func hide_panel() -> void:
	visible = false

func _refresh() -> void:
	var stage: int = GameManager.forge_stage
	_stage_label.text = "Stan: [color=#ff6a00]%s[/color]" % GameManager.FORGE_STAGE_NAMES[stage]
	_stage_label.bbcode_enabled = true

	for c in _req_list.get_children():
		c.queue_free()

	if stage >= 3:
		_build_btn.visible = false
		_done_label.visible = true
		_done_label.text = "[color=#39FF14]✓ Tunel Wyjściowy gotowy!\nBramka na Zewnętrzne Wysypisko odblokowana.[/color]"
		_done_label.bbcode_enabled = true
		return

	_done_label.visible = false
	_build_btn.visible = true

	var next: int = stage + 1
	var req: Dictionary = GameManager.FORGE_REQUIREMENTS[next]
	_title.text = "Buduj: %s" % GameManager.FORGE_STAGE_NAMES[next]

	for mat in req:
		var needed: int = req[mat]
		var have: int = GameManager.building_materials.get(mat, 0)
		var row := HBoxContainer.new()
		var lbl := RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col: String = "#39FF14" if have >= needed else "#ff4444"
		var name_str: String = GameManager.building_material_names.get(mat, mat)
		lbl.text = "[color=%s]%s: %d / %d[/color]" % [col, name_str, have, needed]
		lbl.add_theme_font_size_override("normal_font_size", 12)
		row.add_child(lbl)
		_req_list.add_child(row)

	_build_btn.disabled = not GameManager.can_expand_forge()
	_build_btn.text = "🔨 Buduj Etap %d" % next

func _on_build() -> void:
	GameManager.try_expand_forge()

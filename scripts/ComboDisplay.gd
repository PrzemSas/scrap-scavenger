extends Label

var _combo_system: Node = null
var _flash_timer: float = 0.0

func _ready() -> void:
	visible = false
	# Find combo system after a frame
	await get_tree().process_frame
	_combo_system = get_tree().get_first_node_in_group("combo_system")
	if not _combo_system:
		var main = get_tree().current_scene
		if main:
			_combo_system = main.get_node_or_null("ComboSystem")
	if _combo_system and _combo_system.has_signal("combo_changed"):
		_combo_system.combo_changed.connect(_on_combo)

func _on_combo(count: int, mult: float) -> void:
	if count < 3:
		visible = false
		return
	visible = true
	text = "COMBO x%d (%.1fx)" % [count, mult]
	_flash_timer = 0.3
	if mult >= 3.0:
		add_theme_color_override("font_color", Color("#FFD700"))
	elif mult >= 2.0:
		add_theme_color_override("font_color", Color("#00e5ff"))
	elif mult >= 1.5:
		add_theme_color_override("font_color", Color("#ff6a00"))
	else:
		add_theme_color_override("font_color", Color("#888"))

func _process(delta: float) -> void:
	if _flash_timer > 0:
		_flash_timer -= delta
		modulate.a = 1.0
	elif visible:
		modulate.a = lerp(modulate.a, 0.6, delta * 2.0)

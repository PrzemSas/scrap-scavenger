extends Label
func _ready()->void:
	visible=false
	await get_tree().process_frame
	var cs=get_tree().current_scene.get_node_or_null("ComboSystem")
	if cs: cs.combo_changed.connect(_on)
func _on(count:int,mult:float)->void:
	if count<3: visible=false; return
	visible=true; text="COMBO x%d (%.1fx)"%[count,mult]
	if mult>=2.0: add_theme_color_override("font_color",Color("#FFD700"))
	else: add_theme_color_override("font_color",Color("#ff6a00"))

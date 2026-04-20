extends Node

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	var hud = _get_hud()
	if not hud: return
	match event.keycode:
		KEY_1: hud._show_panel("inv")
		KEY_2: hud._show_panel("sort")
		KEY_3: hud._show_panel("furnace")
		KEY_4: hud._show_panel("shop")
		KEY_5: hud._show_panel("forge")
		KEY_6: hud._show_panel("stats")
		KEY_7: hud._show_panel("craft")
		KEY_8: hud._show_panel("leaderboard")
		KEY_9: hud._show_panel("encyclopedia")
		KEY_ESCAPE: _close_all(hud)

func _get_hud() -> Control:
	var main = get_tree().current_scene
	if not main: return null
	var canvas = main.get_node_or_null("CanvasLayer")
	if not canvas: return null
	return canvas.get_node_or_null("HUD")

func _close_all(hud: Control) -> void:
	if hud.has_method("_toggle"):
		for p in hud._panels:
			p.visible = false

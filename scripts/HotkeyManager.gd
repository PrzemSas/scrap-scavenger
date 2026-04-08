extends Node
func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	var main = get_tree().current_scene
	if not main: return
	var canvas = main.get_node_or_null("CanvasLayer")
	if not canvas: return
	var hud = canvas.get_node_or_null("HUD")
	if not hud or not hud.has_method("_show_panel"): return
	match event.keycode:
		KEY_1: hud._show_panel("inv")
		KEY_2: hud._show_panel("sort")
		KEY_3: hud._show_panel("furnace")
		KEY_4: hud._show_panel("shop")
		KEY_5: hud._show_panel("forge")
		KEY_6: hud._show_panel("stats")

extends Control
@onready var dots:Control=$MapBG/Dots
func _process(_d:float)->void:
	for c in dots.get_children(): c.queue_free()
	var sm=get_tree().current_scene.get_node_or_null("SpawnManager")
	if not sm: return
	for ch in sm.get_children():
		if ch is Area3D:
			var dot=ColorRect.new(); dot.size=Vector2(4,4)
			dot.position=Vector2((ch.position.x/24.0+0.5)*120-2,(ch.position.z/24.0+0.5)*120-2)
			var r=0; if "scrap_data" in ch: r=ch.scrap_data.get("rarity",0)
			dot.color=[Color("#888"),Color("#ff6a00"),Color("#00e5ff"),Color("#FFD700")][r]
			dots.add_child(dot)

extends Control
const WORLD_HALF:=44.0
const MAP_SIZE:=130.0
@onready var dots:Control=$MapBG/Dots
@onready var player_dot:ColorRect=$MapBG/PlayerDot
func _world_to_map(wx:float,wz:float)->Vector2:
	var nx:float=(wx/WORLD_HALF*0.5+0.5)*MAP_SIZE
	var ny:float=(wz/WORLD_HALF*0.5+0.5)*MAP_SIZE
	return Vector2(nx,ny)
func _process(_d:float)->void:
	for c in dots.get_children(): c.queue_free()
	var sm=get_tree().current_scene.get_node_or_null("SpawnManager")
	if sm:
		for ch in sm.get_children():
			if ch is Area3D:
				var mp:=_world_to_map(ch.position.x,ch.position.z)
				var dot:=ColorRect.new(); dot.size=Vector2(5,5)
				dot.position=mp-Vector2(2.5,2.5)
				var r:int=0; if "scrap_data" in ch: r=ch.scrap_data.get("rarity",0)
				dot.color=[Color("#666"),Color("#ff6a00"),Color("#00e5ff"),Color("#FFD700")][r]
				dots.add_child(dot)
	# Markery stosów złomu
	var jp=get_tree().current_scene.get_node_or_null("JunkPiles")
	if jp and jp.has_method("_find_player"):
		for pd in jp._piles:
			var mp:=_world_to_map(pd.spawn_pos.x,pd.spawn_pos.z)
			var dot:=ColorRect.new(); dot.size=Vector2(7,7)
			dot.position=mp-Vector2(3.5,3.5)
			if pd.searching:
				dot.color=Color("#ffff00")  # żółty — szukanie
			elif pd.cooldown>0.0:
				dot.color=Color("#333")     # ciemny — wyczerpany
			else:
				dot.color=Color("#8B4513")  # brązowy — dostępny
			dots.add_child(dot)
	var player=get_tree().current_scene.get_node_or_null("Player")
	if player:
		var mp:=_world_to_map(player.global_position.x,player.global_position.z)
		player_dot.position=mp-Vector2(4,4)
		player_dot.size=Vector2(8,8)
	else:
		player_dot.position=Vector2(MAP_SIZE/2-4,MAP_SIZE/2-4)

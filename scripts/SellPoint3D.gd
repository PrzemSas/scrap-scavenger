extends Area3D
func _ready()->void: GameManager.inventory_changed.connect(_upd); _upd()
func _upd()->void:
	var t:int=0
	for i in GameManager.inventory: t+=i.get("value",1)
	var vl=get_node_or_null("ValueLabel")
	if vl: vl.text="%dc"%t if t>0 else ""; vl.visible=t>0
func _on_input_event(_c:Node,ev:InputEvent,_p:Vector3,_n:Vector3,_i:int)->void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index==MOUSE_BUTTON_LEFT:
		if GameManager.inventory.size()>0: GameManager.sell_all(); AudioManager.play_sell()
func _on_mouse_entered()->void: pass
func _on_mouse_exited()->void: pass

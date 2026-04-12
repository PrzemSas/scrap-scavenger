extends Area3D
func _ready()->void:
	GameManager.inventory_changed.connect(_upd)
	GameManager.ingots_changed.connect(_upd)
	body_exited.connect(_on_body_exited)
	_upd()
func _upd()->void:
	var t:int=0
	for i in GameManager.inventory: t+=i.get("value",1)
	for ig in GameManager.ingots: t+=ig.get("value",1)
	var vl=get_node_or_null("ValueLabel")
	if vl: vl.text="%dc"%t if t>0 else ""; vl.visible=t>0
func _on_body_entered(body:Node3D)->void:
	if not body.is_in_group("player"): return
	GameManager.near_sell_point=true
	GameManager.proximity_entered.emit("sell")
func _on_body_exited(body:Node3D)->void:
	if not body.is_in_group("player"): return
	GameManager.near_sell_point=false
	GameManager.proximity_exited.emit("sell")

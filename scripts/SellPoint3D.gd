extends Area3D
func _ready()->void:
	GameManager.inventory_changed.connect(_upd)
	_upd()
func _upd()->void:
	var t:int=0
	for i in GameManager.inventory: t+=i.get("value",1)
	var vl=get_node_or_null("ValueLabel")
	if vl: vl.text="%dc"%t if t>0 else ""; vl.visible=t>0
func _on_body_entered(body:Node3D)->void:
	if body.is_in_group("player") and GameManager.inventory.size()>0:
		GameManager.sell_all()
		AudioManager.play_sell()
		GameManager.notification.emit("Sold! +coins")

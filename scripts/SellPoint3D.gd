extends Area3D
var _last_coins:int=0
var _popup_scene=preload("res://scenes/effects/CoinPopup.tscn")
func _ready()->void:
	GameManager.inventory_changed.connect(_upd)
	GameManager.ingots_changed.connect(_upd)
	GameManager.coins_changed.connect(_on_coins_changed)
	body_exited.connect(_on_body_exited)
	_last_coins=GameManager.coins
	_upd()
func _upd()->void:
	var t:int=0
	for i in GameManager.inventory: t+=i.get("value",1)
	for ig in GameManager.ingots: t+=ig.get("value",1)
	var vl=get_node_or_null("ValueLabel")
	if vl: vl.text="%dc"%t if t>0 else ""; vl.visible=t>0
func _on_coins_changed(new_amount:int)->void:
	var diff=new_amount-_last_coins
	_last_coins=new_amount
	if diff<=0 or not GameManager.near_sell_point: return
	var popup=_popup_scene.instantiate()
	get_parent().add_child(popup)
	popup.global_position=global_position+Vector3(0,2.5,0)
	popup.setup(diff,Color(1,0.84,0,1))
func _on_body_entered(body:Node3D)->void:
	if not body.is_in_group("player"): return
	GameManager.near_sell_point=true
	GameManager.proximity_entered.emit("sell")
func _on_body_exited(body:Node3D)->void:
	if not body.is_in_group("player"): return
	GameManager.near_sell_point=false
	GameManager.proximity_exited.emit("sell")

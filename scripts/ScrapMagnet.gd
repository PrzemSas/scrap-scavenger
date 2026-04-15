extends Node3D
var magnet_range:float=0.0
func _ready()->void:
	GameManager.upgrade_purchased.connect(func(_id):
		if GameManager.upgrades.get("click_power",0)>=5: magnet_range=5.0
		elif GameManager.upgrades.get("click_power",0)>=3: magnet_range=3.0
	)
func _process(delta:float)->void:
	if magnet_range<=0: return
	var players:=get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var player:=players[0] as Node3D
	var sm=get_parent().get_node_or_null("SpawnManager")
	if not sm: return
	for c in sm.get_children():
		if c is Area3D and c.has_method("collect"):
			var dist:=(player.global_position-c.global_position)
			dist.y=0
			if dist.length()<magnet_range:
				c.global_position+=dist.normalized()*delta*4.0

extends Node3D
var _t:float=0.0
var active:bool=false
func _ready()->void:
	GameManager.upgrade_purchased.connect(func(_id): active=GameManager.upgrades.get("click_power",0)>=2)
func _process(delta:float)->void:
	if not active: return
	_t+=delta
	var interval:float=5.0 if GameManager.forge_purchases.get("auto_collect_2",0)>0 else 10.0
	if _t>=interval:
		_t=0.0
		if GameManager.inventory.size()<GameManager.max_slots:
			var sm=get_parent().get_node_or_null("SpawnManager")
			if sm:
				var d=sm._roll_scrap()
				if GameManager.add_to_inventory(d): GameManager.add_coins(d.get("value",1))

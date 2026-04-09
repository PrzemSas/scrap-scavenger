extends Node3D
var magnet_range:float=0.0
func _ready()->void:
	GameManager.upgrade_purchased.connect(func(_id):
		if GameManager.upgrades.get("click_power",0)>=5: magnet_range=5.0
		elif GameManager.upgrades.get("click_power",0)>=3: magnet_range=3.0
	)
func _process(delta:float)->void:
	if magnet_range<=0: return
	var sm=get_parent().get_node_or_null("SpawnManager")
	if not sm: return
	for c in sm.get_children():
		if c is Area3D and c.has_method("collect"):
			c.position+=-c.position.normalized()*delta*0.3

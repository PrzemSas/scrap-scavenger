extends Node3D
func _ready()->void:
	visible=false
	GameManager.upgrade_purchased.connect(func(_id): visible=GameManager.upgrades.get("auto_sort",0)>0)

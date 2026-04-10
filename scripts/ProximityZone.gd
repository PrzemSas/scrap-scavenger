extends Area3D
@export var panel_id:String=""
func _ready()->void:
	body_entered.connect(func(b:Node3D):
		if b.is_in_group("player"): GameManager.proximity_entered.emit(panel_id))
	body_exited.connect(func(b:Node3D):
		if b.is_in_group("player"): GameManager.proximity_exited.emit(panel_id))

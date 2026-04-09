extends Label3D
var _t:float=0.0
func setup(amount:int,color:Color)->void:
	text="+%d"%amount; modulate=color
func _process(delta:float)->void:
	_t+=delta; position.y+=3.0*delta; modulate.a=1.0-(_t/0.8)
	if _t>=0.8: queue_free()

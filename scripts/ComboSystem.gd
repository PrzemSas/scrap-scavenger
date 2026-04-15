extends Node
signal combo_changed(count:int,mult:float)
var count:int=0
var _timer:float=0.0
func _ready()->void:
	GameManager.coins_changed.connect(func(_c):
		count=min(count+1,20); _timer=2.0
		var m:=get_multiplier(); combo_changed.emit(count,m); GameManager.combo_mult=m)
func _process(delta:float)->void:
	if count>0:
		_timer-=delta
		if _timer<=0: count=0; combo_changed.emit(0,1.0); GameManager.combo_mult=1.0
func get_multiplier()->float:
	if count<3: return 1.0
	elif count<6: return 1.2
	elif count<10: return 1.5
	elif count<15: return 2.0
	else: return 3.0

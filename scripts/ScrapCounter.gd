extends Label
func _ready()->void:
	GameManager.coins_changed.connect(func(_c): _r())
	GameManager.inventory_changed.connect(_r); _r()
func _r()->void:
	text="📦%d  ♻%d  🔥%d  💰%d"%[GameManager.inventory.size(),GameManager.sorted_materials.size(),GameManager.ingots.size(),GameManager.coins]

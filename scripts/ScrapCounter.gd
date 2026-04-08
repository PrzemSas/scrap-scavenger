extends Label

func _ready() -> void:
	GameManager.coins_changed.connect(_update)
	GameManager.inventory_changed.connect(_update2)
	_update(0)

func _update(_c: int) -> void:
	_refresh()

func _update2() -> void:
	_refresh()

func _refresh() -> void:
	var inv = GameManager.inventory.size()
	var sorted = GameManager.sorted_materials.size()
	var ingots = GameManager.ingots.size()
	text = "📦%d  ♻%d  🔥%d  💰%d" % [inv, sorted, ingots, GameManager.coins]

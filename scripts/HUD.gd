extends Control

@onready var coin_label: Label = $CoinLabel
@onready var inv_label: Label = $InvLabel

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	_on_coins_changed(GameManager.coins)
	_on_inventory_changed()

func _on_coins_changed(amount: int) -> void:
	coin_label.text = "%d COINS" % amount

func _on_inventory_changed() -> void:
	inv_label.text = "INV %d/%d" % [GameManager.inventory.size(), GameManager.max_slots]

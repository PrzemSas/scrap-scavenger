extends Node

signal coins_changed(new_amount: int)
signal inventory_changed()

var coins: int = 0
var inventory: Array = []
var max_slots: int = 8
var click_power: int = 1

func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit(coins)
		return true
	return false

func add_to_inventory(item_data: Dictionary) -> bool:
	if inventory.size() >= max_slots:
		return false
	inventory.append(item_data)
	inventory_changed.emit()
	return true

func remove_from_inventory(index: int) -> void:
	if index >= 0 and index < inventory.size():
		inventory.remove_at(index)
		inventory_changed.emit()

func sell_item(index: int) -> void:
	if index >= 0 and index < inventory.size():
		var item = inventory[index]
		add_coins(item.get("value", 1))
		remove_from_inventory(index)

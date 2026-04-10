extends Node

signal crafting_changed()

var recipes: Array = [
	{"id":"steel_plate","name":"Steel Plate","ingredients":{"Steel Ingot":2},"value":60,"desc":"2x Steel Ingot → Strong plate"},
	{"id":"copper_wire_bundle","name":"Wire Bundle","ingredients":{"Copper Wire":3},"value":100,"desc":"3x Copper Wire → Dense bundle"},
	{"id":"circuit","name":"Circuit Board+","ingredients":{"Silicon Wafer":1,"Copper Wire":1},"value":120,"desc":"Wafer + Wire → Advanced board"},
	{"id":"titan_frame","name":"Titan Frame","ingredients":{"Titanium Rod":2,"Steel Ingot":1},"value":200,"desc":"2x Ti Rod + Steel → Ultra frame"},
	{"id":"forge_core","name":"Forge Core","ingredients":{"Forge Shard":1,"Gold Ingot":1},"value":500,"desc":"Shard + Gold → Legendary core"},
	{"id":"scrap_crown","name":"Scrap Crown","ingredients":{"Gold Ingot":2,"Titanium Rod":1,"Forge Shard":1},"value":1000,"desc":"The ultimate crafted item"},
]

var crafted_items: Array = []

func can_craft(recipe: Dictionary) -> bool:
	var ingredients = recipe.get("ingredients", {})
	for ingot_name in ingredients:
		var needed = ingredients[ingot_name]
		var have = _count_ingot(ingot_name)
		if have < needed:
			return false
	return true

func craft(recipe: Dictionary) -> bool:
	if not can_craft(recipe):
		return false
	var ingredients = recipe.get("ingredients", {})
	for ingot_name in ingredients:
		var needed = ingredients[ingot_name]
		_remove_ingots(ingot_name, needed)
	crafted_items.append({"name": recipe.name, "value": recipe.value, "id": recipe.id})
	GameManager.notification.emit("⚒ Crafted: %s (%dc)" % [recipe.name, recipe.value])
	AudioManager.play_upgrade()
	crafting_changed.emit()
	return true

func sell_crafted(index: int) -> void:
	if index >= 0 and index < crafted_items.size():
		GameManager.add_coins(crafted_items[index].value)
		crafted_items.remove_at(index)
		AudioManager.play_sell()
		crafting_changed.emit()

func sell_all_crafted() -> void:
	var total: int = 0
	for item in crafted_items:
		total += item.value
	crafted_items.clear()
	if total > 0:
		GameManager.add_coins(total)
		AudioManager.play_sell()
	crafting_changed.emit()

func _count_ingot(ingot_name: String) -> int:
	var count: int = 0
	for ig in GameManager.ingots:
		if ig.get("name", "") == ingot_name:
			count += 1
	return count

func _remove_ingots(ingot_name: String, amount: int) -> void:
	var removed: int = 0
	var i: int = GameManager.ingots.size() - 1
	while i >= 0 and removed < amount:
		if GameManager.ingots[i].get("name", "") == ingot_name:
			GameManager.ingots.remove_at(i)
			removed += 1
		i -= 1
	GameManager.ingots_changed.emit()

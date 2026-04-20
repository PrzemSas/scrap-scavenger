extends Node3D

var magnet_range: float = 0.0

func _ready() -> void:
	_update_range()
	GameManager.upgrade_purchased.connect(func(_id): _update_range())

func _update_range() -> void:
	var lvl: int = GameManager.upgrades.get("click_power", 0)
	if lvl >= 5:
		magnet_range = 8.0
	elif lvl >= 3:
		magnet_range = 5.0
	else:
		magnet_range = 0.0

func _process(delta: float) -> void:
	if magnet_range <= 0.0:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player := players[0] as Node3D
	var sm = get_parent().get_node_or_null("SpawnManager")
	if not sm:
		return
	for c in sm.get_children():
		if c is Area3D and c.has_method("collect"):
			var diff: Vector3 = player.global_position - c.global_position
			diff.y = 0.0
			if diff.length() < magnet_range:
				c.global_position += diff.normalized() * delta * 6.0

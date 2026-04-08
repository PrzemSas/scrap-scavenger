extends Node3D

var magnet_range: float = 0.0

func _ready() -> void:
	GameManager.upgrade_purchased.connect(_check)
	_check("")

func _check(_id: String) -> void:
	if GameManager.upgrades.get("click_power", 0) >= 5:
		magnet_range = 5.0
	elif GameManager.upgrades.get("click_power", 0) >= 3:
		magnet_range = 3.0

func _process(delta: float) -> void:
	if magnet_range <= 0.0:
		return
	var spawn_mgr = get_parent().get_node_or_null("SpawnManager")
	if not spawn_mgr:
		return
	for child in spawn_mgr.get_children():
		if child is Area3D and child.has_method("collect"):
			var dir: Vector3 = -child.position.normalized()
			child.position += dir * delta * 0.3

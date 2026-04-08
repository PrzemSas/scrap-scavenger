extends Node3D

# When player clicks, nearby items get pulled closer
var magnet_range: float = 0.0  # 0 = disabled
var _pull_targets: Array = []

func _ready() -> void:
	GameManager.upgrade_purchased.connect(_check)
	_check("")

func _check(_id: String) -> void:
	# Activate after click_power level 3
	if GameManager.upgrades.get("click_power", 0) >= 3:
		magnet_range = 3.0
	if GameManager.upgrades.get("click_power", 0) >= 5:
		magnet_range = 5.0

func _process(delta: float) -> void:
	if magnet_range <= 0:
		return
	# Pull items toward center of spawn area slowly
	var spawn_mgr = get_parent().get_node_or_null("SpawnManager")
	if not spawn_mgr:
		return
	for child in spawn_mgr.get_children():
		if child is Area3D and child.has_method("collect"):
			# Gently drift items inward
			var dir = -child.position.normalized()
			child.position += dir * delta * 0.3

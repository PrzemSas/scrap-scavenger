extends Node3D

var _timer: float = 0.0
var active: bool = false

func _ready() -> void:
	GameManager.upgrade_purchased.connect(_check_unlock)
	_check_unlock("")

func _check_unlock(_id: String) -> void:
	active = GameManager.upgrades.get("click_power", 0) >= 2

func _get_interval() -> float:
	if GameManager.forge_purchases.get("auto_collect_2", 0) > 0:
		return 5.0
	return 10.0

func _process(delta: float) -> void:
	if not active: return
	_timer += delta
	if _timer >= _get_interval():
		_timer = 0.0
		_auto_collect()

func _auto_collect() -> void:
	if GameManager.inventory.size() >= GameManager.max_slots: return
	var spawn_mgr = get_parent().get_node_or_null("SpawnManager")
	if spawn_mgr and spawn_mgr.has_method("_roll_scrap"):
		var data = spawn_mgr._roll_scrap()
		if GameManager.add_to_inventory(data):
			GameManager.add_coins(data.get("value", 1))

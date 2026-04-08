extends Node3D

var _timer: float = 0.0
var collect_interval: float = 10.0  # seconds between auto-collects
var active: bool = false

func _ready() -> void:
	GameManager.upgrade_purchased.connect(_check_unlock)
	_check_unlock("")

func _check_unlock(_id: String) -> void:
	# Activate if click_power upgrade >= 2 (means player has some progress)
	active = GameManager.upgrades.get("click_power", 0) >= 2

func _process(delta: float) -> void:
	if not active:
		return
	_timer += delta
	if _timer >= collect_interval:
		_timer = 0.0
		_auto_collect()

func _auto_collect() -> void:
	if GameManager.inventory.size() >= GameManager.max_slots:
		return
	# Roll random scrap using SpawnManager logic
	var spawn_mgr = get_parent().get_node_or_null("SpawnManager")
	if spawn_mgr and spawn_mgr.has_method("_roll_scrap"):
		var data = spawn_mgr._roll_scrap()
		if GameManager.add_to_inventory(data):
			GameManager.add_coins(data.get("value", 1))

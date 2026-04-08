extends Node3D

const WORKER_SCENE = preload("res://scenes/objects/WorkerNPC.tscn")
var workers: Array = []
var max_workers: int = 0

func _ready() -> void:
	GameManager.upgrade_purchased.connect(_check)
	GameManager.prestige_done.connect(func(_t): _check(""))
	_check("")

func _check(_id: String) -> void:
	# Workers from forge shop
	var purchased = GameManager.forge_purchases.get("hire_worker", 0)
	max_workers = purchased
	_update_workers()

func _update_workers() -> void:
	# Remove excess
	while workers.size() > max_workers:
		var w = workers.pop_back()
		w.queue_free()
	# Add missing
	while workers.size() < max_workers:
		var w = WORKER_SCENE.instantiate()
		w.position = Vector3(randf_range(-6, 6), 0.4, randf_range(-6, 6))
		w.worker_id = workers.size()
		w.active = true
		var tag = w.get_node_or_null("NameTag")
		if tag:
			tag.text = "WORKER #%d" % (workers.size() + 1)
		add_child(w)
		workers.append(w)

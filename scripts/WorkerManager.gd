extends Node3D

const WORKER_SCENE = preload("res://scenes/objects/WorkerNPC.tscn")
var workers: Array = []

func _ready() -> void:
	GameManager.upgrade_purchased.connect(func(_id): _check())
	_check()

func _check() -> void:
	var target: int = GameManager.forge_purchases.get("hire_worker", 0)
	while workers.size() < target:
		var w = WORKER_SCENE.instantiate()
		w.position = Vector3(randf_range(-5, 5), 0.4, randf_range(-5, 5))
		w.worker_id = workers.size()
		w.active = true
		var tag = w.get_node_or_null("Tag")
		if tag:
			tag.text = "WORKER #%d" % (workers.size() + 1)
		add_child(w)
		workers.append(w)

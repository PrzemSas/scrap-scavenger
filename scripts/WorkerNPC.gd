extends Node3D

var _timer: float = 0.0
var _target: Vector3 = Vector3.ZERO
var _speed: float = 2.0
var active: bool = false
var worker_id: int = 0

func _ready() -> void:
	_pick_target()

func _process(delta: float) -> void:
	if not active:
		return
	var dir = (_target - position)
	dir.y = 0
	if dir.length() < 0.5:
		_pick_target()
		return
	position += dir.normalized() * _speed * delta
	position.y = 0.4
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 5.0)
	_timer += delta
	if _timer >= 3.0:
		_timer = 0.0
		_try_collect()

func _pick_target() -> void:
	_target = Vector3(randf_range(-7, 7), 0, randf_range(-7, 7))

func _try_collect() -> void:
	var sm = get_tree().current_scene.get_node_or_null("SpawnManager")
	if not sm:
		return
	for ch in sm.get_children():
		if ch is Area3D and ch.has_method("collect"):
			if ch.global_position.distance_to(global_position) < 2.0:
				ch.collect()
				return

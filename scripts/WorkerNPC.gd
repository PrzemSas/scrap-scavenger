extends Node3D

var _timer: float = 0.0
var _target: Vector3 = Vector3.ZERO
var _speed: float = 2.5
var active: bool = false
var worker_id: int = 0
var _chase_target: Node3D = null
var _notify_cooldown: float = 0.0
const WANDER_HALF := 38.0
const COLLECT_DIST := 2.5
const DETECT_DIST := 20.0
const NOTIFY_INTERVAL := 5.0

func _ready() -> void:
	_pick_target()

func _process(delta: float) -> void:
	if not active:
		return
	_chase_target = _find_nearest_scrap()
	var dest: Vector3
	if _chase_target and is_instance_valid(_chase_target):
		dest = _chase_target.global_position
		dest.y = 0.4
	else:
		dest = _target
	var dir = (dest - position)
	dir.y = 0
	if dir.length() < 0.5:
		if _chase_target and is_instance_valid(_chase_target):
			if _chase_target.has_method("collect"):
				_chase_target.collect()
				if _notify_cooldown <= 0.0:
					GameManager.notification.emit("Worker #%d collected scrap!" % (worker_id + 1))
					_notify_cooldown = NOTIFY_INTERVAL
			_chase_target = null
		_pick_target()
		return
	position += dir.normalized() * _speed * (1.0 + GameManager.worker_speed_bonus) * delta
	position.y = 0.4
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 5.0)
	_timer += delta
	if _notify_cooldown > 0.0:
		_notify_cooldown -= delta
	if _timer >= 2.0:
		_timer = 0.0
		if not _chase_target:
			_pick_target()

func _pick_target() -> void:
	_target = Vector3(randf_range(-WANDER_HALF, WANDER_HALF), 0.4, randf_range(-WANDER_HALF, WANDER_HALF))

func _find_nearest_scrap() -> Node3D:
	var sm = get_tree().current_scene.get_node_or_null("SpawnManager")
	if not sm:
		return null
	var best: Node3D = null
	var best_dist: float = DETECT_DIST * (1.0 + GameManager.detect_range_bonus)
	for ch in sm.get_children():
		if ch is Area3D and ch.has_method("collect"):
			var d: float = ch.global_position.distance_to(global_position)
			if d < best_dist:
				best_dist = d
				best = ch
	return best

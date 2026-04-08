extends Node3D

var _timer: float = 0.0
var _move_target: Vector3 = Vector3.ZERO
var _speed: float = 2.0
var _collect_range: float = 1.5
var worker_id: int = 0
var active: bool = false

func _ready() -> void:
	_pick_target()

func _process(delta: float) -> void:
	if not active:
		return
	# Move toward target
	var dir = (_move_target - position).normalized()
	dir.y = 0
	position += dir * _speed * delta
	position.y = 0.4
	# Rotate toward movement
	if dir.length() > 0.01:
		var target_rot = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, delta * 5.0)
	# Check if near target
	if position.distance_to(_move_target) < 0.5:
		_pick_target()
	# Try to collect nearby scrap
	_timer += delta
	if _timer >= 2.0:
		_timer = 0.0
		_try_collect()

func _pick_target() -> void:
	_move_target = Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))

func _try_collect() -> void:
	var spawn_mgr = get_tree().current_scene.get_node_or_null("SpawnManager")
	if not spawn_mgr:
		return
	for child in spawn_mgr.get_children():
		if child is Area3D and child.has_method("collect"):
			if child.global_position.distance_to(global_position) < _collect_range:
				child.collect()
				return

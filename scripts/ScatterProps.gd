extends Node3D

func _ready() -> void:
	await get_tree().process_frame
	for child in get_children():
		if child is StaticBody3D:
			continue
		if not (child is Node3D):
			continue
		var meshes: Array = []
		_find_meshes(child, meshes)
		if meshes.is_empty():
			continue
		# Build combined AABB in child's local space
		var combined := AABB()
		var first := true
		for mi: MeshInstance3D in meshes:
			if not mi.mesh:
				continue
			# transform mesh AABB to child's local space
			var rel: Transform3D = child.transform.inverse() * mi.global_transform
			var m: AABB = rel * mi.mesh.get_aabb()
			if first:
				combined = m
				first = false
			else:
				combined = combined.merge(m)
		if first:  # no valid meshes
			continue
		var body := StaticBody3D.new()
		child.add_child(body)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = combined.size.max(Vector3(0.1, 0.1, 0.1))
		cs.position = combined.get_center()
		cs.shape = shape
		body.add_child(cs)

func _find_meshes(node: Node, result: Array) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_find_meshes(child, result)

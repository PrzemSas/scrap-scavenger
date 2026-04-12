extends Node3D

func _ready() -> void:
	for child in get_children():
		if not (child is MeshInstance3D):
			continue
		var mesh = child.mesh
		if not (mesh is BoxMesh):
			continue
		var body := StaticBody3D.new()
		body.transform = child.transform
		add_child(body)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = (mesh as BoxMesh).size
		cs.shape = shape
		body.add_child(cs)

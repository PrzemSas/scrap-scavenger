extends Node3D

func _ready() -> void:
	for child in get_children():
		if not (child is MeshInstance3D):
			continue
		var mesh = child.mesh
		var body := StaticBody3D.new()
		body.transform = child.transform
		add_child(body)
		var cs := CollisionShape3D.new()
		if mesh is BoxMesh:
			var shape := BoxShape3D.new()
			shape.size = (mesh as BoxMesh).size
			cs.shape = shape
		elif mesh is CylinderMesh:
			var cyl := mesh as CylinderMesh
			var shape := CylinderShape3D.new()
			shape.radius = maxf(cyl.top_radius, cyl.bottom_radius)
			shape.height = cyl.height
			cs.shape = shape
		else:
			continue
		body.add_child(cs)

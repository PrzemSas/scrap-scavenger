@tool
class_name ScrapPile
extends Node3D

@export var pile_radius: float = 2.8
@export var seed_override: int = 0
@export var scrap_types: Array[ScrapType] = []

var _multimeshes: Array[MultiMeshInstance3D] = []

func _ready() -> void:
	_find_multimesh_children()
	_generate_all_piles()

func _find_multimesh_children() -> void:
	_multimeshes.clear()
	for child in get_children():
		if child is MultiMeshInstance3D:
			_multimeshes.append(child as MultiMeshInstance3D)

func _generate_all_piles() -> void:
	var used_seed: int = seed_override if seed_override != 0 else hash(global_position)

	for i in min(scrap_types.size(), _multimeshes.size()):
		var type: ScrapType = scrap_types[i]
		var mmi: MultiMeshInstance3D = _multimeshes[i]

		if type.mesh == null:
			continue

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = type.mesh
		mm.instance_count = type.count

		var rng := RandomNumberGenerator.new()
		rng.seed = used_seed + i * 7919

		for j in type.count:
			var angle := rng.randf() * TAU
			var t := rng.randf()
			var dist := sqrt(t) * pile_radius

			var x := cos(angle) * dist
			var z := sin(angle) * dist
			var height_falloff := max(0.0, 1.0 - dist / pile_radius)
			var y := rng.randf() * type.height_variation * height_falloff

			var xform := Transform3D()
			xform.origin = Vector3(x, y, z)

			if type.random_rotation:
				xform = xform.rotated(Vector3.UP, rng.randf() * TAU)
				xform = xform.rotated(Vector3.RIGHT, rng.randf_range(-PI * 0.7, PI * 0.7))
				xform = xform.rotated(Vector3.FORWARD, rng.randf_range(-PI * 0.5, PI * 0.5))

			var s := rng.randf_range(type.scale_min, type.scale_max)
			xform = xform.scaled(Vector3.ONE * s)

			mm.set_instance_transform(j, xform)

		mmi.multimesh = mm
		if type.material != null:
			mmi.material_override = type.material

func regenerate() -> void:
	_generate_all_piles()

func add_scrap(_type_index: int = 0, _position_offset: Vector3 = Vector3.ZERO) -> void:
	pass

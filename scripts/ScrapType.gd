@tool
class_name ScrapType
extends Resource

@export var name: String = "Nowy typ złomu"
@export var mesh: Mesh = null
@export var material: Material = null
@export var count: int = 40
@export var scale_min: float = 0.7
@export var scale_max: float = 1.8
@export var height_variation: float = 1.4
@export var random_rotation: bool = true

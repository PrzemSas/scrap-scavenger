extends Control

const MAP_SIZE: float = 120.0
const WORLD_SIZE: float = 24.0

@onready var map_bg: ColorRect = $MapBG
@onready var dots_container: Control = $MapBG/Dots
@onready var player_dot: ColorRect = $MapBG/PlayerDot

func _process(_delta: float) -> void:
	_update_dots()

func _update_dots() -> void:
	# Clear old dots
	for c in dots_container.get_children():
		c.queue_free()
	# Find spawn manager
	var spawn = get_tree().get_first_node_in_group("spawn_manager")
	if not spawn:
		# Try to find it manually
		var main = get_tree().current_scene
		if main:
			spawn = main.get_node_or_null("SpawnManager")
	if not spawn:
		return
	for child in spawn.get_children():
		if child is Area3D and child.has_method("collect"):
			var world_pos = child.global_position
			var map_x = (world_pos.x / WORLD_SIZE + 0.5) * MAP_SIZE
			var map_y = (world_pos.z / WORLD_SIZE + 0.5) * MAP_SIZE
			var dot = ColorRect.new()
			dot.size = Vector2(4, 4)
			dot.position = Vector2(map_x - 2, map_y - 2)
			var rarity = 0
			if child.has_method("setup") and "scrap_data" in child:
				rarity = child.scrap_data.get("rarity", 0)
			var colors = [Color("#888888"), Color("#ff6a00"), Color("#00e5ff"), Color("#FFD700")]
			dot.color = colors[rarity]
			dots_container.add_child(dot)

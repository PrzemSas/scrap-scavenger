extends Area3D

@export var target_scene: String = ""
@export var label_text: String = "[E] Enter"
@export var spawn_pos: Vector3 = Vector3.ZERO
@export var required_stage: int = 0

var _player_inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if required_stage > 0:
		GameManager.forge_stage_changed.connect(func(_s): _update_hint())

func _is_unlocked() -> bool:
	return required_stage == 0 or GameManager.forge_stage >= required_stage

func _update_hint() -> void:
	if not _player_inside: return
	if _is_unlocked():
		GameManager.pile_hint_changed.emit(label_text)
	else:
		GameManager.pile_hint_changed.emit("🔒 Wymaga Etap %d Podziemnej Kuzni" % required_stage)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		_update_hint()

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		GameManager.pile_hint_changed.emit("")

func _process(_delta: float) -> void:
	if _player_inside and target_scene != "" and _is_unlocked():
		if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("interact"):
			GameManager.pile_hint_changed.emit("")
			SceneTransition.spawn_override = spawn_pos
			SceneTransition.go(target_scene)

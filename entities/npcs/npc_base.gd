extends CharacterBody3D
## Base NPC entity. Stands in place, detects nearby player, can be interacted with.

@export var npc_data: NPCData = null

var _player_nearby := false

@onready var model: Node3D = $Model
@onready var interaction_area: Area3D = $InteractionArea

func _ready() -> void:
	add_to_group("npcs")

	if interaction_area:
		interaction_area.body_entered.connect(_on_body_entered)
		interaction_area.body_exited.connect(_on_body_exited)

	if npc_data and model:
		_build_model()

func get_display_name() -> String:
	if npc_data:
		return npc_data.display_name
	return "NPC"

func get_dialog_lines() -> PackedStringArray:
	if npc_data:
		return npc_data.dialog_lines
	return PackedStringArray(["..."])

func interact() -> void:
	if npc_data:
		EventBus.dialog_started.emit(npc_data.display_name, npc_data.dialog_lines)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_nearby = true
		EventBus.npc_in_range.emit(self, true)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player_nearby = false
		EventBus.npc_in_range.emit(self, false)

func _build_model() -> void:
	for child in model.get_children():
		child.queue_free()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = npc_data.color_primary
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = npc_data.color_secondary

	var s: float = npc_data.model_scale

	# Body (robe-like cylinder)
	var body := CSGCylinder3D.new()
	body.radius = 0.3 * s
	body.height = 1.0 * s
	body.transform.origin = Vector3(0, 0.5 * s, 0)
	body.material = mat
	model.add_child(body)

	# Head
	var head := CSGSphere3D.new()
	head.radius = 0.22 * s
	head.transform.origin = Vector3(0, 1.15 * s, 0)
	head.material = mat2
	model.add_child(head)

	# Hat / hood (small cone-like shape using a cylinder)
	var hat := CSGCylinder3D.new()
	hat.radius = 0.18 * s
	hat.height = 0.3 * s
	hat.transform.origin = Vector3(0, 1.4 * s, 0)
	hat.material = mat
	model.add_child(hat)

	# Eyes
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.1, 0.1)
	for side in [-1, 1]:
		var eye := CSGSphere3D.new()
		eye.radius = 0.035 * s
		eye.transform.origin = Vector3(0.08 * side * s, 1.18 * s, 0.18 * s)
		eye.material = eye_mat
		model.add_child(eye)

	# Name label above head
	var name_label := Label3D.new()
	name_label.text = npc_data.display_name
	name_label.font_size = 24
	name_label.transform.origin = Vector3(0, 1.8 * s, 0)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.modulate = Color(0.9, 0.85, 0.6, 0.9)
	model.add_child(name_label)

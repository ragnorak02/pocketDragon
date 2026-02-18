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

	var built := ModelFactory.build_npc_model(npc_data, true)
	for child in built.get_children():
		built.remove_child(child)
		model.add_child(child)
	built.queue_free()

	# Add subtle idle sway
	ModelFactory.add_idle_bob(model, 0.02, 1.5)

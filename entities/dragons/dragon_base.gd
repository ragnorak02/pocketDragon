extends CharacterBody3D
## Wild dragon entity for overworld. Rarer, visually distinct, capturable.
const MF = preload("res://utils/model_factory.gd")

@export var dragon_data: DragonData = null
@export var patrol_radius: float = 6.0
@export var patrol_speed: float = 1.5
@export var detection_range: float = 4.0

var _origin: Vector3
var _patrol_target: Vector3
var _player: Node3D = null
var _wait_timer := 0.0
var _hover_offset := 0.0

@onready var model: Node3D = $Model
@onready var detection_area: Area3D = $DetectionArea

func _ready() -> void:
	_origin = global_position
	_pick_patrol_target()
	add_to_group("wild_dragons")

	if detection_area:
		var shape: SphereShape3D = detection_area.get_child(0).shape if detection_area.get_child_count() > 0 else null
		if shape:
			shape.radius = detection_range
		detection_area.body_entered.connect(_on_body_entered)

	if dragon_data and model:
		_build_model()

func _physics_process(delta: float) -> void:
	if not GameManager.is_gameplay_active():
		velocity = Vector3.ZERO
		return

	# Hover animation
	_hover_offset += delta * 2.0
	if model:
		model.position.y = sin(_hover_offset) * 0.15 + 0.1

	if not is_on_floor():
		velocity.y -= 20.0 * delta

	# Patrol (dragons don't chase, they wait)
	_wait_timer -= delta
	if _wait_timer > 0:
		velocity.x = 0
		velocity.z = 0
	else:
		var to_target := _patrol_target - global_position
		to_target.y = 0
		if to_target.length() < 0.5:
			_wait_timer = randf_range(2.0, 5.0)
			_pick_patrol_target()
		else:
			var dir := to_target.normalized()
			velocity.x = dir.x * patrol_speed
			velocity.z = dir.z * patrol_speed
			if model:
				model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 4.0 * delta)

	move_and_slide()

func _pick_patrol_target() -> void:
	var angle := randf() * TAU
	var dist := randf() * patrol_radius
	_patrol_target = _origin + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player = body
		_trigger_battle()

func _trigger_battle() -> void:
	velocity = Vector3.ZERO
	if dragon_data:
		EventBus.battle_requested.emit(dragon_data, self)

func _build_model() -> void:
	for child in model.get_children():
		child.queue_free()

	var built := MF.build_dragon_model(dragon_data)
	for child in built.get_children():
		built.remove_child(child)
		model.add_child(child)
	built.queue_free()

	# Element aura particles instead of flat disc
	MF.add_dragon_aura(model, dragon_data.color_primary, dragon_data.model_scale)

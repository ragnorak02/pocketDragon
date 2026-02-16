extends CharacterBody3D
## Wild dragon entity for overworld. Rarer, visually distinct, capturable.

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

	var mat := StandardMaterial3D.new()
	mat.albedo_color = dragon_data.color_primary
	mat.emission_enabled = true
	mat.emission = dragon_data.color_primary * 0.3
	mat.emission_energy_multiplier = 0.4

	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = dragon_data.color_secondary

	var s: float = dragon_data.model_scale

	# Body
	var body := CSGSphere3D.new()
	body.radius = 0.6 * s
	body.transform.origin = Vector3(0, 0.6, 0)
	body.material = mat
	model.add_child(body)

	# Head
	var head := CSGSphere3D.new()
	head.radius = 0.35 * s
	head.transform.origin = Vector3(0.5, 1.0, 0) * s
	head.material = mat
	model.add_child(head)

	# Snout
	var snout := CSGBox3D.new()
	snout.size = Vector3(0.3, 0.15, 0.2) * s
	snout.transform.origin = Vector3(0.8, 0.9, 0) * s
	snout.material = mat
	model.add_child(snout)

	# Wings
	for side in [-1, 1]:
		var wing := CSGBox3D.new()
		wing.size = Vector3(0.08, 0.6, 1.0) * s
		wing.transform.origin = Vector3(-0.1, 1.0, 0.6 * side) * s
		wing.rotation_degrees = Vector3(0, 0, -15 * side)
		wing.material = mat2
		model.add_child(wing)

	# Tail
	var tail := CSGCylinder3D.new()
	tail.radius = 0.1 * s
	tail.height = 1.0 * s
	tail.transform.origin = Vector3(-0.7, 0.4, 0) * s
	tail.rotation_degrees = Vector3(0, 0, 70)
	tail.material = mat
	model.add_child(tail)

	# Eyes (glowing)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1, 0.9, 0.3)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1, 0.8, 0.2)
	eye_mat.emission_energy_multiplier = 1.5
	for side in [-1, 1]:
		var eye := CSGSphere3D.new()
		eye.radius = 0.06 * s
		eye.transform.origin = Vector3(0.7, 1.1, 0.12 * side) * s
		eye.material = eye_mat
		model.add_child(eye)

	# Element aura (subtle glow underneath)
	var aura := CSGCylinder3D.new()
	aura.radius = 0.8 * s
	aura.height = 0.05
	aura.transform.origin = Vector3(0, 0.02, 0)
	var aura_mat := StandardMaterial3D.new()
	aura_mat.albedo_color = Color(dragon_data.color_primary, 0.3)
	aura_mat.emission_enabled = true
	aura_mat.emission = dragon_data.color_primary
	aura_mat.emission_energy_multiplier = 0.8
	aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura.material = aura_mat
	model.add_child(aura)

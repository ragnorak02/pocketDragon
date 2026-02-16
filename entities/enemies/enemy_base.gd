extends CharacterBody3D
## Base enemy entity for overworld. Patrols, detects player, triggers battle.

@export var enemy_data: EnemyData = null
@export var patrol_radius: float = 4.0
@export var patrol_speed: float = 2.0
@export var detection_range: float = 3.0
@export var chase_speed: float = 4.0

var _origin: Vector3
var _patrol_target: Vector3
var _player: Node3D = null
var _chasing := false
var _wait_timer := 0.0

@onready var model: Node3D = $Model
@onready var detection_area: Area3D = $DetectionArea

func _ready() -> void:
	_origin = global_position
	_pick_patrol_target()
	add_to_group("enemies")

	# Set detection area range
	if detection_area:
		var shape: SphereShape3D = detection_area.get_child(0).shape if detection_area.get_child_count() > 0 else null
		if shape:
			shape.radius = detection_range
		detection_area.body_entered.connect(_on_body_entered)

	# Build visual from enemy_data
	if enemy_data and model:
		_build_model()

func _physics_process(delta: float) -> void:
	if not GameManager.is_gameplay_active():
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity.y -= 20.0 * delta

	if _chasing and _player and is_instance_valid(_player):
		# Chase player
		var dir := (_player.global_position - global_position).normalized()
		dir.y = 0
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed

		# Check if close enough to trigger battle
		var dist := global_position.distance_to(_player.global_position)
		if dist < 1.2:
			_trigger_battle()
			return

		# Face movement direction
		if dir.length() > 0.1 and model:
			model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
	else:
		# Patrol
		_wait_timer -= delta
		if _wait_timer > 0:
			velocity.x = 0
			velocity.z = 0
		else:
			var to_target := _patrol_target - global_position
			to_target.y = 0
			if to_target.length() < 0.5:
				_wait_timer = randf_range(1.0, 3.0)
				_pick_patrol_target()
			else:
				var dir := to_target.normalized()
				velocity.x = dir.x * patrol_speed
				velocity.z = dir.z * patrol_speed
				if model:
					model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), 5.0 * delta)

	move_and_slide()

func _pick_patrol_target() -> void:
	var angle := randf() * TAU
	var dist := randf() * patrol_radius
	_patrol_target = _origin + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		_player = body
		_chasing = true
		EventBus.enemy_spotted_player.emit(self)

func _trigger_battle() -> void:
	_chasing = false
	velocity = Vector3.ZERO
	if enemy_data:
		EventBus.battle_requested.emit(enemy_data, self)

func _build_model() -> void:
	# Clear existing children
	for child in model.get_children():
		child.queue_free()

	var mat := StandardMaterial3D.new()
	mat.albedo_color = enemy_data.color_primary
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = enemy_data.color_secondary

	var scale_val: float = enemy_data.model_scale

	if enemy_data.enemy_id == "slime":
		# Slime: squished sphere
		var body := CSGSphere3D.new()
		body.radius = 0.5 * scale_val
		body.transform.origin = Vector3(0, 0.35, 0)
		body.transform = body.transform.scaled_local(Vector3(1.0, 0.7, 1.0))
		body.material = mat
		model.add_child(body)
		# Eyes
		for side in [-1, 1]:
			var eye := CSGSphere3D.new()
			eye.radius = 0.08
			eye.transform.origin = Vector3(0.15 * side, 0.45, 0.3) * scale_val
			eye.material = mat2
			model.add_child(eye)
	else:
		# Goblin / generic: body + head
		var body := CSGCylinder3D.new()
		body.radius = 0.25 * scale_val
		body.height = 0.7 * scale_val
		body.transform.origin = Vector3(0, 0.35, 0)
		body.material = mat
		model.add_child(body)

		var head := CSGSphere3D.new()
		head.radius = 0.2 * scale_val
		head.transform.origin = Vector3(0, 0.85 * scale_val, 0)
		head.material = mat
		model.add_child(head)

		# Ears (for goblin)
		for side in [-1, 1]:
			var ear := CSGBox3D.new()
			ear.size = Vector3(0.05, 0.15, 0.08) * scale_val
			ear.transform.origin = Vector3(0.18 * side, 0.95, 0) * scale_val
			ear.rotation_degrees = Vector3(0, 0, -20 * side)
			ear.material = mat2
			model.add_child(ear)

		# Eyes
		for side in [-1, 1]:
			var eye := CSGSphere3D.new()
			eye.radius = 0.04 * scale_val
			eye.transform.origin = Vector3(0.08 * side, 0.88, 0.15) * scale_val
			var eye_mat := StandardMaterial3D.new()
			eye_mat.albedo_color = Color(0.9, 0.2, 0.1)
			eye_mat.emission_enabled = true
			eye_mat.emission = Color(0.8, 0.1, 0.05)
			eye_mat.emission_energy_multiplier = 0.5
			eye.material = eye_mat
			model.add_child(eye)

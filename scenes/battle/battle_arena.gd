extends Node3D
## Battle arena visual layer. Communicates with BattleManager via EventBus.
const MF = preload("res://utils/model_factory.gd")

@onready var battle_camera: Camera3D = $BattleCamera
@onready var player_marker: Node3D = $PlayerMarker
@onready var enemy_marker: Node3D = $EnemyMarker
@onready var battle_hud: CanvasLayer = $BattleHUD
@onready var battle_ground: CSGBox3D = $BattleGround

var _overworld_camera: Camera3D = null
var _player_node: Node3D = null
var _player_model: Node3D = null
var _enemy_model: Node3D = null
var _is_active := false

func _ready() -> void:
	visible = false
	if battle_hud:
		battle_hud.visible = false

	EventBus.battle_state_changed.connect(_on_battle_state_changed)
	EventBus.action_executed.connect(_on_action_executed)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.capture_attempted.connect(_on_capture_attempted)
	EventBus.capture_result.connect(_on_capture_result)
	EventBus.dragon_swapped_in_battle.connect(_on_dragon_swapped)

func activate(camera: Camera3D, player: Node3D) -> void:
	_overworld_camera = camera
	_player_node = player
	_is_active = true
	visible = true

	# Position battle arena near player
	global_position = player.global_position + Vector3(0, 0, 0)

	# Create combatant models
	_spawn_player_dragon_model()
	_spawn_enemy_model()

	# Camera transition: lerp from overworld to battle camera
	battle_camera.current = false
	await _transition_camera_to_battle()

	if battle_hud:
		battle_hud.visible = true
		battle_hud.initialize()

func deactivate(camera: Camera3D, player: Node3D) -> void:
	if battle_hud:
		battle_hud.visible = false

	await _transition_camera_to_overworld()

	# Clean up models
	if _player_model:
		_player_model.queue_free()
		_player_model = null
	if _enemy_model:
		_enemy_model.queue_free()
		_enemy_model = null

	visible = false
	_is_active = false

func _transition_camera_to_battle() -> void:
	battle_camera.current = true
	# Animate camera (quick zoom into battle position)
	var tween := create_tween()
	battle_camera.global_position = _overworld_camera.global_position
	battle_camera.global_rotation = _overworld_camera.global_rotation
	tween.set_parallel(true)
	tween.tween_property(battle_camera, "global_position", _get_battle_camera_pos(), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(battle_camera, "global_rotation_degrees", Vector3(-20, -180, 0), 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(false)
	await tween.finished

func _transition_camera_to_overworld() -> void:
	if _overworld_camera:
		var tween := create_tween()
		tween.tween_property(battle_camera, "global_position", _overworld_camera.global_position, 0.8).set_trans(Tween.TRANS_CUBIC)
		await tween.finished
		_overworld_camera.current = true

func _get_battle_camera_pos() -> Vector3:
	var center := (player_marker.global_position + enemy_marker.global_position) / 2.0
	return center + Vector3(0, 4, 6)

func _spawn_player_dragon_model() -> void:
	if _player_model:
		_player_model.queue_free()

	var dragon = PartyManager.get_active_dragon()
	if dragon == null or dragon.base_data == null:
		return

	_player_model = _create_dragon_model(dragon.base_data)
	_player_model.global_position = player_marker.global_position
	_player_model.rotation_degrees.y = 90  # Face enemy
	add_child(_player_model)

func _spawn_enemy_model() -> void:
	if _enemy_model:
		_enemy_model.queue_free()

	var data = BattleManager.enemy_data
	if data == null:
		return

	if BattleManager.is_wild_dragon:
		_enemy_model = _create_dragon_model(data)
	else:
		_enemy_model = _create_enemy_model(data)

	_enemy_model.global_position = enemy_marker.global_position
	_enemy_model.rotation_degrees.y = -90  # Face player
	add_child(_enemy_model)

func _create_dragon_model(data) -> Node3D:
	var root := MF.build_dragon_model(data, 1.5)
	MF.add_dragon_aura(root, data.color_primary, data.model_scale * 1.5)
	MF.add_idle_bob(root, 0.06, 1.8)
	return root

func _create_enemy_model(data: EnemyData) -> Node3D:
	var root := MF.build_enemy_model(data, 1.5)
	MF.add_idle_bob(root, 0.04, 2.0)
	return root

func _on_battle_state_changed(_old: StringName, new_state: StringName) -> void:
	if not _is_active:
		return
	if battle_hud:
		battle_hud.update_state(new_state)

func _on_action_executed(action: Dictionary, result: Dictionary) -> void:
	if not _is_active:
		return
	# Attack animation
	if action.get("type") == "attack":
		var is_player_attack: bool = result.get("attacker", "") != BattleManager._get_enemy_name()
		var attacker_model: Node3D = _player_model if is_player_attack else _enemy_model
		var target_model: Node3D = _enemy_model if is_player_attack else _player_model
		if attacker_model and target_model:
			_play_attack_animation(attacker_model, target_model)

func _play_attack_animation(attacker: Node3D, target: Node3D) -> void:
	var original_pos := attacker.global_position
	var target_pos := target.global_position
	var slide_pos := original_pos.lerp(target_pos, 0.3)

	var tween := create_tween()
	tween.tween_property(attacker, "global_position", slide_pos, 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(_on_hit_impact.bind(target))
	tween.tween_property(attacker, "global_position", original_pos, 0.25).set_trans(Tween.TRANS_CUBIC)

func _on_hit_impact(target_node: Node3D) -> void:
	if not is_instance_valid(target_node):
		return
	# Scale squash
	var tween := create_tween()
	tween.tween_property(target_node, "scale", Vector3(1.15, 0.85, 1.15), 0.1)
	tween.tween_property(target_node, "scale", Vector3.ONE, 0.15)

	# Spawn impact burst particles
	_spawn_impact_particles(target_node.global_position + Vector3(0, 0.5, 0))

	# Camera shake
	_shake_camera(0.2, 0.15)

func _spawn_impact_particles(pos: Vector3) -> void:
	var particles := CPUParticles3D.new()
	particles.amount = 12
	particles.lifetime = 0.4
	particles.one_shot = true
	particles.emitting = true
	particles.explosiveness = 0.9
	particles.global_position = pos

	particles.direction = Vector3(0, 1, 0)
	particles.spread = 180.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 5.0
	particles.gravity = Vector3(0, -8, 0)
	particles.scale_amount_min = 0.03
	particles.scale_amount_max = 0.08

	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.9, 0.3, 1.0))
	gradient.add_point(0.3, Color(1, 0.5, 0.1, 0.8))
	gradient.set_color(1, Color(0.8, 0.2, 0.1, 0.0))
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	particles.color_ramp = color_ramp

	add_child(particles)
	# Auto-cleanup after particles finish
	var timer := get_tree().create_timer(particles.lifetime + 0.5)
	timer.timeout.connect(particles.queue_free)

func _shake_camera(duration: float, intensity: float) -> void:
	if not battle_camera:
		return
	var original_pos := battle_camera.position
	var tween := create_tween()
	var steps := 6
	for i in steps:
		var offset := Vector3(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity),
			0
		) * (1.0 - float(i) / float(steps))
		tween.tween_property(battle_camera, "position", original_pos + offset, duration / float(steps))
	tween.tween_property(battle_camera, "position", original_pos, duration / float(steps))

func _on_damage_dealt(target_name: String, amount: int, _is_critical: bool) -> void:
	if not _is_active:
		return
	if battle_hud:
		battle_hud.show_damage_number(amount, target_name == BattleManager._get_enemy_name())

func _on_capture_attempted(dragon_name: String, gem_tier: int) -> void:
	if not _is_active or not _enemy_model:
		return
	# Capture animation: shake enemy model
	var tween := create_tween()
	for i in 3:
		tween.tween_property(_enemy_model, "rotation_degrees:z", 10.0, 0.1)
		tween.tween_property(_enemy_model, "rotation_degrees:z", -10.0, 0.1)
	tween.tween_property(_enemy_model, "rotation_degrees:z", 0.0, 0.1)

func _on_capture_result(success: bool, _dragon_name: String) -> void:
	if not _is_active or not _enemy_model:
		return
	if success:
		# Shrink and fade enemy model
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_enemy_model, "scale", Vector3(0.01, 0.01, 0.01), 0.5)
		tween.set_parallel(false)
		tween.tween_callback(func(): _enemy_model.visible = false)

func _on_dragon_swapped(dragon_instance) -> void:
	if not _is_active:
		return
	_spawn_player_dragon_model()

## Shared factory for building entity CSG models with toon shader materials.
## Centralizes dragon, enemy, and NPC model construction that was previously duplicated.

const TOON_SHADER_PATH := "res://assets/shaders/shader_toon.gdshader"
const JELLY_SHADER_PATH := "res://assets/shaders/shader_jelly.gdshader"

static var _toon_shader: Shader = null
static var _jelly_shader: Shader = null

static func _get_toon_shader() -> Shader:
	if _toon_shader == null:
		_toon_shader = load(TOON_SHADER_PATH)
	return _toon_shader

static func _get_jelly_shader() -> Shader:
	if _jelly_shader == null:
		_jelly_shader = load(JELLY_SHADER_PATH)
	return _jelly_shader

## Create a toon ShaderMaterial with the given color and optional parameters.
static func make_toon_material(color: Color, rim_color: Color = Color.WHITE, rim_intensity: float = 0.4, emission: float = 0.0, metallic: float = 0.0) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _get_toon_shader()
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("rim_color", rim_color)
	mat.set_shader_parameter("rim_intensity", rim_intensity)
	mat.set_shader_parameter("emission_strength", emission)
	mat.set_shader_parameter("metallic_val", metallic)
	return mat

## Create a jelly ShaderMaterial for slime-type enemies.
static func make_jelly_material(color: Color, rim_color: Color = Color.WHITE) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _get_jelly_shader()
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("rim_color", rim_color)
	return mat

# ─── Dragon Model ──────────────────────────────────────────────────────────────

## Build a dragon CSG model and return the root Node3D.
## scale_mult allows battle arena to use 1.5x scale.
static func build_dragon_model(data, scale_mult: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var s: float = data.model_scale * scale_mult

	var body_mat := make_toon_material(
		data.color_primary,
		Color(data.color_primary).lightened(0.4),
		0.5,
		0.15
	)
	var wing_mat := make_toon_material(
		data.color_secondary,
		Color(data.color_secondary).lightened(0.3),
		0.3
	)

	# Body
	var body := CSGSphere3D.new()
	body.radius = 0.6 * s
	body.transform.origin = Vector3(0, 0.6, 0)
	body.material = body_mat
	root.add_child(body)

	# Head
	var head := CSGSphere3D.new()
	head.radius = 0.35 * s
	head.transform.origin = Vector3(0.5, 1.0, 0) * s
	head.material = body_mat
	root.add_child(head)

	# Snout
	var snout := CSGBox3D.new()
	snout.size = Vector3(0.3, 0.15, 0.2) * s
	snout.transform.origin = Vector3(0.8, 0.9, 0) * s
	snout.material = body_mat
	root.add_child(snout)

	# Wings
	for side in [-1, 1]:
		var wing := CSGBox3D.new()
		wing.size = Vector3(0.08, 0.6 * scale_mult, 1.0 * scale_mult) * s
		wing.transform.origin = Vector3(-0.1, 1.0, 0.6 * side) * s
		wing.rotation_degrees = Vector3(0, 0, -15 * side)
		wing.material = wing_mat
		root.add_child(wing)

	# Tail
	var tail := CSGCylinder3D.new()
	tail.radius = 0.1 * s
	tail.height = 1.0 * s
	tail.transform.origin = Vector3(-0.7, 0.4, 0) * s
	tail.rotation_degrees = Vector3(0, 0, 70)
	tail.material = body_mat
	root.add_child(tail)

	# Eyes (glowing)
	var eye_mat := make_toon_material(
		Color(1, 0.9, 0.3),
		Color(1, 1, 0.6),
		0.6,
		1.5
	)
	for side in [-1, 1]:
		var eye := CSGSphere3D.new()
		eye.radius = 0.06 * s
		eye.transform.origin = Vector3(0.7, 1.1, 0.12 * side) * s
		eye.material = eye_mat
		root.add_child(eye)

	# Horns (new detail)
	var horn_mat := make_toon_material(
		Color(data.color_secondary).darkened(0.3),
		Color(0.8, 0.7, 0.5),
		0.3,
		0.0,
		0.2
	)
	for side in [-1, 1]:
		var horn := CSGCylinder3D.new()
		horn.radius = 0.04 * s
		horn.height = 0.25 * s
		horn.transform.origin = Vector3(0.35, 1.25, 0.1 * side) * s
		horn.rotation_degrees = Vector3(-20 * side, 0, -30 * side)
		horn.material = horn_mat
		root.add_child(horn)

	return root

## Add a CPUParticles3D aura ring underneath a dragon model.
static func add_dragon_aura(parent: Node3D, color: Color, scale: float = 1.0) -> CPUParticles3D:
	var particles := CPUParticles3D.new()
	particles.name = "AuraParticles"
	particles.amount = 20
	particles.lifetime = 1.5
	particles.one_shot = false
	particles.explosiveness = 0.0
	particles.emitting = true

	# Emit in a ring at the dragon's feet
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	particles.emission_ring_axis = Vector3.UP
	particles.emission_ring_height = 0.1
	particles.emission_ring_radius = 0.7 * scale
	particles.emission_ring_inner_radius = 0.5 * scale
	particles.transform.origin = Vector3(0, 0.05, 0)

	particles.direction = Vector3(0, 1, 0)
	particles.initial_velocity_min = 0.3
	particles.initial_velocity_max = 0.6
	particles.gravity = Vector3.ZERO
	particles.scale_amount_min = 0.03
	particles.scale_amount_max = 0.06

	# Color gradient: element color fading to transparent
	var gradient := Gradient.new()
	gradient.set_color(0, Color(color, 0.8))
	gradient.add_point(0.5, Color(color, 0.4))
	gradient.set_color(1, Color(color, 0.0))
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	particles.color_ramp = color_ramp

	parent.add_child(particles)
	return particles

# ─── Enemy Models ──────────────────────────────────────────────────────────────

## Build a slime enemy model with jelly shader.
static func build_slime_model(data, scale_mult: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var s: float = data.model_scale * scale_mult

	var body_mat := make_jelly_material(
		data.color_primary,
		Color(data.color_primary).lightened(0.5)
	)

	# Body (squished sphere)
	var body := CSGSphere3D.new()
	body.radius = 0.5 * s
	body.transform.origin = Vector3(0, 0.35, 0)
	body.transform = body.transform.scaled_local(Vector3(1.0, 0.7, 1.0))
	body.material = body_mat
	root.add_child(body)

	# Eyes
	var eye_mat := make_toon_material(
		data.color_secondary,
		Color.WHITE,
		0.5,
		0.3
	)
	for side in [-1, 1]:
		var eye := CSGSphere3D.new()
		eye.radius = 0.08
		eye.transform.origin = Vector3(0.15 * side, 0.45, 0.3) * s
		eye.material = eye_mat
		root.add_child(eye)

	# Mouth (small dark indentation)
	var mouth_mat := make_toon_material(
		Color(data.color_primary).darkened(0.5),
		Color(0.1, 0.1, 0.1),
		0.2
	)
	var mouth := CSGBox3D.new()
	mouth.size = Vector3(0.12, 0.04, 0.04) * s
	mouth.transform.origin = Vector3(0, 0.32, 0.35) * s
	mouth.material = mouth_mat
	root.add_child(mouth)

	return root

## Build a goblin/generic enemy model with toon shader.
static func build_goblin_model(data, scale_mult: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var s: float = data.model_scale * scale_mult

	var body_mat := make_toon_material(
		data.color_primary,
		Color(data.color_primary).lightened(0.3),
		0.4
	)
	var accent_mat := make_toon_material(
		data.color_secondary,
		Color(data.color_secondary).lightened(0.3),
		0.3
	)

	# Body
	var body := CSGCylinder3D.new()
	body.radius = 0.25 * s
	body.height = 0.7 * s
	body.transform.origin = Vector3(0, 0.35, 0)
	body.material = body_mat
	root.add_child(body)

	# Head
	var head := CSGSphere3D.new()
	head.radius = 0.2 * s
	head.transform.origin = Vector3(0, 0.85 * s, 0)
	head.material = body_mat
	root.add_child(head)

	# Ears (pointy)
	for side in [-1, 1]:
		var ear := CSGBox3D.new()
		ear.size = Vector3(0.05, 0.15, 0.08) * s
		ear.transform.origin = Vector3(0.18 * side, 0.95, 0) * s
		ear.rotation_degrees = Vector3(0, 0, -20 * side)
		ear.material = accent_mat
		root.add_child(ear)

	# Eyes (glowing red)
	var eye_mat := make_toon_material(
		Color(0.9, 0.2, 0.1),
		Color(1, 0.4, 0.2),
		0.6,
		0.5
	)
	for side in [-1, 1]:
		var eye := CSGSphere3D.new()
		eye.radius = 0.04 * s
		eye.transform.origin = Vector3(0.08 * side, 0.88, 0.15) * s
		eye.material = eye_mat
		root.add_child(eye)

	# Weapon (small club)
	var weapon_mat := make_toon_material(
		Color(0.4, 0.3, 0.2),
		Color(0.6, 0.5, 0.3),
		0.2,
		0.0,
		0.1
	)
	var club := CSGCylinder3D.new()
	club.radius = 0.04 * s
	club.height = 0.4 * s
	club.transform.origin = Vector3(0.25, 0.5, 0.1) * s
	club.rotation_degrees = Vector3(0, 0, -30)
	club.material = weapon_mat
	root.add_child(club)

	return root

## Build an enemy model based on enemy_id.
static func build_enemy_model(data, scale_mult: float = 1.0) -> Node3D:
	if data.enemy_id == "slime":
		return build_slime_model(data, scale_mult)
	else:
		return build_goblin_model(data, scale_mult)

# ─── NPC Model ─────────────────────────────────────────────────────────────────

## Build an NPC model with toon shader and name label.
static func build_npc_model(data, include_label: bool = true) -> Node3D:
	var root := Node3D.new()
	var s: float = data.model_scale

	var body_mat := make_toon_material(
		data.color_primary,
		Color(data.color_primary).lightened(0.3),
		0.35
	)
	var skin_mat := make_toon_material(
		data.color_secondary,
		Color(data.color_secondary).lightened(0.2),
		0.25
	)

	# Body (robe)
	var body := CSGCylinder3D.new()
	body.radius = 0.3 * s
	body.height = 1.0 * s
	body.transform.origin = Vector3(0, 0.5 * s, 0)
	body.material = body_mat
	root.add_child(body)

	# Head
	var head := CSGSphere3D.new()
	head.radius = 0.22 * s
	head.transform.origin = Vector3(0, 1.15 * s, 0)
	head.material = skin_mat
	root.add_child(head)

	# Hat / hood
	var hat_mat := make_toon_material(
		Color(data.color_primary).darkened(0.15),
		Color(data.color_primary).lightened(0.2),
		0.3
	)
	var hat := CSGCylinder3D.new()
	hat.radius = 0.18 * s
	hat.height = 0.3 * s
	hat.transform.origin = Vector3(0, 1.4 * s, 0)
	hat.material = hat_mat
	root.add_child(hat)

	# Hat brim
	var brim := CSGCylinder3D.new()
	brim.radius = 0.28 * s
	brim.height = 0.04 * s
	brim.transform.origin = Vector3(0, 1.27 * s, 0)
	brim.material = hat_mat
	root.add_child(brim)

	# Eyes
	var eye_mat := make_toon_material(Color(0.1, 0.1, 0.1), Color.WHITE, 0.2)
	for side in [-1, 1]:
		var eye := CSGSphere3D.new()
		eye.radius = 0.035 * s
		eye.transform.origin = Vector3(0.08 * side * s, 1.18 * s, 0.18 * s)
		eye.material = eye_mat
		root.add_child(eye)

	# Name label
	if include_label:
		var name_label := Label3D.new()
		name_label.text = data.display_name
		name_label.font_size = 24
		name_label.transform.origin = Vector3(0, 1.8 * s, 0)
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		name_label.modulate = Color(0.9, 0.85, 0.6, 0.9)
		name_label.outline_size = 4
		name_label.outline_modulate = Color(0, 0, 0, 0.6)
		root.add_child(name_label)

	return root

# ─── Idle Animations ───────────────────────────────────────────────────────────

## Add a simple breathing/bob idle animation to a model root.
static func add_idle_bob(model: Node3D, amplitude: float = 0.05, speed: float = 2.0) -> AnimationPlayer:
	var anim_player := AnimationPlayer.new()
	anim_player.name = "IdleAnimPlayer"

	var anim_lib := AnimationLibrary.new()
	var anim := Animation.new()
	anim.loop_mode = Animation.LOOP_LINEAR
	anim.length = TAU / speed

	# Y position track
	var track_idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, ".:position:y")
	var base_y := model.position.y
	var steps := 8
	for i in steps + 1:
		var t := float(i) / float(steps) * anim.length
		var val := base_y + sin(float(i) / float(steps) * TAU) * amplitude
		anim.track_insert_key(track_idx, t, val)

	anim_lib.add_animation("idle_bob", anim)
	anim_player.add_animation_library("", anim_lib)

	model.add_child(anim_player)
	anim_player.play("idle_bob")
	return anim_player

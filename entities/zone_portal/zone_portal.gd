extends Area3D
## Portal that triggers a zone transition when the player enters it.

var target_zone_path: String = ""
var portal_label: String = "Unknown"

var _glow_tween: Tween = null

func _ready() -> void:
	collision_layer = 4  # Triggers layer
	collision_mask = 1   # Player layer
	monitoring = true
	monitorable = false

	body_entered.connect(_on_body_entered)

	_build_visual()

func _build_visual() -> void:
	# Glowing pillar pair with toon shader
	var pillar_mat := ModelFactory.make_toon_material(
		Color(0.3, 0.5, 0.8),
		Color(0.5, 0.7, 1.0),
		0.5,
		0.8,
		0.3
	)

	for side in [-1, 1]:
		var pillar := CSGCylinder3D.new()
		pillar.radius = 0.15
		pillar.height = 3.0
		pillar.transform.origin = Vector3(side * 1.0, 1.5, 0)
		pillar.material = pillar_mat
		add_child(pillar)

	# Pillar top orbs
	var orb_mat := ModelFactory.make_toon_material(
		Color(0.5, 0.7, 1.0),
		Color(0.7, 0.9, 1.0),
		0.4,
		1.5
	)
	for side in [-1, 1]:
		var orb := CSGSphere3D.new()
		orb.radius = 0.12
		orb.transform.origin = Vector3(side * 1.0, 3.1, 0)
		orb.material = orb_mat
		add_child(orb)

	# Archway top
	var arch := CSGBox3D.new()
	arch.size = Vector3(2.3, 0.2, 0.3)
	arch.transform.origin = Vector3(0, 3.0, 0)
	arch.material = pillar_mat
	add_child(arch)

	# Swirling energy with portal shader
	var energy := CSGSphere3D.new()
	energy.radius = 0.6
	energy.transform.origin = Vector3(0, 1.5, 0)
	var energy_shader := load("res://assets/shaders/shader_portal_energy.gdshader")
	var energy_mat := ShaderMaterial.new()
	energy_mat.shader = energy_shader
	energy.material = energy_mat
	energy.name = "Energy"
	add_child(energy)

	# Swirl particles around the energy sphere
	var particles := CPUParticles3D.new()
	particles.name = "SwirlParticles"
	particles.amount = 30
	particles.lifetime = 2.0
	particles.emitting = true
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	particles.emission_ring_axis = Vector3.UP
	particles.emission_ring_height = 2.0
	particles.emission_ring_radius = 0.8
	particles.emission_ring_inner_radius = 0.4
	particles.transform.origin = Vector3(0, 1.5, 0)
	particles.direction = Vector3(0, 1, 0)
	particles.initial_velocity_min = 0.2
	particles.initial_velocity_max = 0.5
	particles.gravity = Vector3.ZERO
	particles.angular_velocity_min = 90.0
	particles.angular_velocity_max = 180.0
	particles.scale_amount_min = 0.02
	particles.scale_amount_max = 0.05
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.4, 0.6, 1.0, 0.9))
	gradient.add_point(0.5, Color(0.3, 0.5, 0.9, 0.5))
	gradient.set_color(1, Color(0.2, 0.3, 0.8, 0.0))
	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	particles.color_ramp = color_ramp
	add_child(particles)

	# Label above
	var label_3d := Label3D.new()
	label_3d.text = portal_label
	label_3d.font_size = 32
	label_3d.transform.origin = Vector3(0, 3.5, 0)
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.modulate = Color(0.8, 0.9, 1.0, 0.9)
	label_3d.outline_size = 4
	label_3d.outline_modulate = Color(0, 0, 0, 0.5)
	add_child(label_3d)

	# Collision shape for portal trigger
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 3.0, 1.5)
	col_shape.shape = shape
	col_shape.transform.origin = Vector3(0, 1.5, 0)
	add_child(col_shape)

func _on_body_entered(body: Node3D) -> void:
	if not (body.is_in_group("player") or body.name == "Player"):
		return
	if GameManager.current_state != GameManager.GameState.OVERWORLD:
		return

	# Calculate spawn position: opposite side of the portal in the target zone
	var spawn_pos := Vector3(-sign(position.x) * 25, 1, position.z)
	EventBus.zone_transition_requested.emit(target_zone_path, spawn_pos)

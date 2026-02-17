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
	# Glowing pillar pair
	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.3, 0.5, 0.8, 1)
	pillar_mat.emission_enabled = true
	pillar_mat.emission = Color(0.2, 0.4, 0.9, 1)
	pillar_mat.emission_energy_multiplier = 1.5

	for side in [-1, 1]:
		var pillar := CSGCylinder3D.new()
		pillar.radius = 0.15
		pillar.height = 3.0
		pillar.transform.origin = Vector3(side * 1.0, 1.5, 0)
		pillar.material = pillar_mat
		add_child(pillar)

	# Archway top
	var arch := CSGBox3D.new()
	arch.size = Vector3(2.3, 0.2, 0.3)
	arch.transform.origin = Vector3(0, 3.0, 0)
	arch.material = pillar_mat
	add_child(arch)

	# Swirling energy (simple sphere)
	var energy := CSGSphere3D.new()
	energy.radius = 0.6
	energy.transform.origin = Vector3(0, 1.5, 0)
	var energy_mat := StandardMaterial3D.new()
	energy_mat.albedo_color = Color(0.4, 0.6, 1.0, 0.5)
	energy_mat.emission_enabled = true
	energy_mat.emission = Color(0.3, 0.5, 1.0, 1)
	energy_mat.emission_energy_multiplier = 2.0
	energy_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	energy.material = energy_mat
	energy.name = "Energy"
	add_child(energy)

	# Label above
	var label_3d := Label3D.new()
	label_3d.text = portal_label
	label_3d.font_size = 32
	label_3d.transform.origin = Vector3(0, 3.5, 0)
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.modulate = Color(0.8, 0.9, 1.0, 0.9)
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

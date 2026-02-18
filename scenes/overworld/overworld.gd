extends Node3D
## Main overworld scene. Loads zones from ZoneData, persists during battle transitions.

@onready var camera: Camera3D = $IsometricCamera
@onready var player: CharacterBody3D = $Player
@onready var battle_arena: Node3D = $BattleArena
@onready var enemies_container: Node3D = $Enemies
@onready var dragons_container: Node3D = $WildDragons
@onready var npcs_container: Node3D = $NPCs
@onready var portals_container: Node3D = $Portals
@onready var decorations_container: Node3D = $Decorations
@onready var ground: CSGBox3D = $Ground
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var dir_light: DirectionalLight3D = $DirectionalLight3D

var _enemy_scene: PackedScene
var _wild_dragon_scene: PackedScene
var _npc_scene: PackedScene
var _portal_scene: PackedScene

var current_zone: ZoneData = null
var _transitioning := false

func _ready() -> void:
	add_to_group("overworld")
	camera.set_target(player)
	GameManager.change_state(GameManager.GameState.OVERWORLD)

	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)
	EventBus.zone_transition_requested.connect(_on_zone_transition)

	# Load entity scenes
	_enemy_scene = load("res://entities/enemies/enemy_base.tscn")
	_wild_dragon_scene = load("res://entities/dragons/dragon_base.tscn")
	_npc_scene = load("res://entities/npcs/npc_base.tscn")
	_portal_scene = load("res://entities/zone_portal/zone_portal.tscn")

	# Load default zone (meadow)
	var default_zone: ZoneData = load("res://data/zones/meadow.tres")
	_load_zone(default_zone)

func _load_zone(zone: ZoneData, spawn_override: Vector3 = Vector3.INF) -> void:
	_clear_zone()
	current_zone = zone

	_apply_environment()
	_spawn_decorations()
	_spawn_overworld_entities()
	_spawn_npcs()
	_spawn_portals()

	# Place player
	if spawn_override != Vector3.INF:
		player.global_position = spawn_override
	else:
		player.global_position = zone.default_spawn

	EventBus.zone_loaded.emit(zone.zone_id)
	EventBus.player_entered_area.emit(zone.zone_name)
	print("[Overworld] Loaded zone: %s" % zone.zone_name)

func _clear_zone() -> void:
	# Clear entity containers — never touch BattleArena, Player, Camera, or HUD
	for child in enemies_container.get_children():
		child.queue_free()
	for child in dragons_container.get_children():
		child.queue_free()
	for child in npcs_container.get_children():
		child.queue_free()
	for child in portals_container.get_children():
		child.queue_free()
	for child in decorations_container.get_children():
		child.queue_free()

func _apply_environment() -> void:
	if not current_zone:
		return

	# Ground — procedural terrain shader
	ground.size = current_zone.ground_size
	var ground_shader := load("res://assets/shaders/shader_ground.gdshader")
	var ground_mat := ShaderMaterial.new()
	ground_mat.shader = ground_shader
	# Derive shader colors from zone ground color
	var gc: Color = current_zone.ground_color
	ground_mat.set_shader_parameter("grass_color", gc)
	ground_mat.set_shader_parameter("dirt_color", Color(gc).darkened(0.2) + Color(0.1, 0.0, -0.05, 0))
	ground_mat.set_shader_parameter("dark_grass_color", Color(gc).darkened(0.3))
	ground.material = ground_mat

	# Environment
	var env: Environment = world_env.environment
	env.background_color = current_zone.sky_color
	env.ambient_light_color = current_zone.ambient_color
	env.ambient_light_energy = current_zone.ambient_energy
	env.fog_light_color = current_zone.fog_color
	env.fog_density = current_zone.fog_density

	# Directional light
	dir_light.light_color = current_zone.light_color
	dir_light.light_energy = current_zone.light_energy

func _spawn_decorations() -> void:
	if not current_zone:
		return

	var trunk_mat := ModelFactory.make_toon_material(
		Color(0.35, 0.22, 0.12),
		Color(0.5, 0.35, 0.2),
		0.25
	)

	var wind_shader: Shader = load("res://assets/shaders/shader_wind_sway.gdshader")
	var rock_shader: Shader = load("res://assets/shaders/shader_rock.gdshader")
	var path_shader: Shader = load("res://assets/shaders/shader_path.gdshader")

	for deco in current_zone.decorations:
		var deco_type: String = deco.get("type", "rock")
		var pos: Vector3 = deco.get("position", Vector3.ZERO)
		var deco_scale: float = deco.get("scale", 1.0)
		var color: Color = deco.get("color", Color.WHITE)

		if deco_type == "tree":
			var tree := Node3D.new()
			tree.position = pos
			tree.add_to_group("zone_decoration")

			var trunk := CSGCylinder3D.new()
			trunk.radius = 0.2 * deco_scale
			trunk.height = 2.0 * deco_scale
			trunk.transform.origin = Vector3(0, 1.0 * deco_scale, 0)
			trunk.material = trunk_mat
			tree.add_child(trunk)

			# Canopy with wind sway shader
			var leaves := CSGSphere3D.new()
			leaves.radius = 1.0 * deco_scale
			leaves.transform.origin = Vector3(0, 2.5 * deco_scale, 0)
			var leaf_mat := ShaderMaterial.new()
			leaf_mat.shader = wind_shader
			leaf_mat.set_shader_parameter("base_color", color)
			leaf_mat.set_shader_parameter("wind_speed", 1.5)
			leaf_mat.set_shader_parameter("wind_strength", 0.12)
			leaves.material = leaf_mat
			tree.add_child(leaves)

			# Lower canopy layer for fullness
			var leaves2 := CSGSphere3D.new()
			leaves2.radius = 0.7 * deco_scale
			leaves2.transform.origin = Vector3(0.3, 2.0 * deco_scale, 0.2)
			var leaf_mat2 := ShaderMaterial.new()
			leaf_mat2.shader = wind_shader
			leaf_mat2.set_shader_parameter("base_color", Color(color).darkened(0.15))
			leaf_mat2.set_shader_parameter("wind_speed", 1.8)
			leaf_mat2.set_shader_parameter("wind_strength", 0.1)
			leaves2.material = leaf_mat2
			tree.add_child(leaves2)

			decorations_container.add_child(tree)

		elif deco_type == "rock":
			var rock := CSGSphere3D.new()
			rock.radius = 0.5 * deco_scale
			rock.transform.origin = pos + Vector3(0, 0.3 * deco_scale, 0)
			rock.transform = rock.transform.scaled_local(Vector3(1.5, 0.8, 1.2))
			var rock_mat := ShaderMaterial.new()
			rock_mat.shader = rock_shader
			rock_mat.set_shader_parameter("color_base", color)
			rock_mat.set_shader_parameter("color_dark", Color(color).darkened(0.3))
			rock_mat.set_shader_parameter("color_highlight", Color(color).lightened(0.2))
			rock.material = rock_mat
			rock.add_to_group("zone_decoration")
			decorations_container.add_child(rock)

		elif deco_type == "path":
			var path_mat := ShaderMaterial.new()
			path_mat.shader = path_shader
			path_mat.set_shader_parameter("stone_color", color)
			path_mat.set_shader_parameter("mortar_color", Color(color).darkened(0.25))

			# Horizontal path
			var path_h := CSGBox3D.new()
			path_h.size = Vector3(40, 0.02, 2.5)
			path_h.transform.origin = pos
			path_h.material = path_mat
			path_h.add_to_group("zone_decoration")
			decorations_container.add_child(path_h)

			# Vertical path
			var path_v := CSGBox3D.new()
			path_v.size = Vector3(2.5, 0.02, 40)
			path_v.transform.origin = pos
			path_v.material = path_mat
			path_v.add_to_group("zone_decoration")
			decorations_container.add_child(path_v)

func _spawn_overworld_entities() -> void:
	if not current_zone:
		return

	# Spawn enemies
	for spawn in current_zone.enemy_spawns:
		if not _enemy_scene:
			break
		var data_path: String = spawn.get("data_path", "")
		var pos: Vector3 = spawn.get("position", Vector3.ZERO)
		if data_path == "" or not ResourceLoader.exists(data_path):
			continue
		var enemy := _enemy_scene.instantiate()
		enemy.position = pos
		enemy.enemy_data = load(data_path)
		enemies_container.add_child(enemy)

	# Spawn wild dragons
	for spawn in current_zone.dragon_spawns:
		if not _wild_dragon_scene:
			break
		var data_path: String = spawn.get("data_path", "")
		var pos: Vector3 = spawn.get("position", Vector3.ZERO)
		if data_path == "" or not ResourceLoader.exists(data_path):
			continue
		var dragon := _wild_dragon_scene.instantiate()
		dragon.position = pos
		dragon.dragon_data = load(data_path)
		dragons_container.add_child(dragon)

func _spawn_npcs() -> void:
	if not current_zone or not _npc_scene:
		return

	for spawn in current_zone.npc_spawns:
		var data_path: String = spawn.get("data_path", "")
		var pos: Vector3 = spawn.get("position", Vector3.ZERO)
		if data_path == "" or not ResourceLoader.exists(data_path):
			continue
		var npc := _npc_scene.instantiate()
		npc.position = pos
		npc.npc_data = load(data_path)
		npcs_container.add_child(npc)

func _spawn_portals() -> void:
	if not current_zone or not _portal_scene:
		return

	for portal_def in current_zone.portals:
		var target_path: String = portal_def.get("target_zone_path", "")
		var pos: Vector3 = portal_def.get("position", Vector3.ZERO)
		var label_text: String = portal_def.get("label", "Unknown")
		if target_path == "":
			continue
		var portal := _portal_scene.instantiate()
		portal.position = pos
		portal.target_zone_path = target_path
		portal.portal_label = label_text
		portals_container.add_child(portal)

func _on_zone_transition(zone_path: String, spawn_position: Vector3) -> void:
	if _transitioning:
		return
	if GameManager.current_state != GameManager.GameState.OVERWORLD:
		return
	_transitioning = true

	# Fade to black
	EventBus.fade_requested.emit(true, 0.4)
	await EventBus.fade_completed

	# Load new zone
	if ResourceLoader.exists(zone_path):
		var new_zone: ZoneData = load(zone_path)
		_load_zone(new_zone, spawn_position)
	else:
		push_error("[Overworld] Zone not found: %s" % zone_path)

	# Fade back
	EventBus.fade_requested.emit(false, 0.4)
	await EventBus.fade_completed

	_transitioning = false

func _on_battle_started() -> void:
	if battle_arena:
		battle_arena.activate(camera, player)

func _on_battle_ended(result: StringName) -> void:
	if battle_arena:
		battle_arena.deactivate(camera, player)
	if result == "defeat":
		# On defeat: heal party and respawn at current zone's default spawn
		PartyManager.heal_all_dragons()
		if current_zone:
			player.global_position = current_zone.default_spawn
		else:
			player.global_position = Vector3(0, 1, 0)

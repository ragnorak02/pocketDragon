extends Node3D
## Main overworld scene. Persists during battle transitions.

@onready var camera: Camera3D = $IsometricCamera
@onready var player: CharacterBody3D = $Player
@onready var battle_arena: Node3D = $BattleArena
@onready var enemies_container: Node3D = $Enemies
@onready var dragons_container: Node3D = $WildDragons

var _enemy_scene: PackedScene
var _wild_dragon_scene: PackedScene

func _ready() -> void:
	camera.set_target(player)
	GameManager.change_state(GameManager.GameState.OVERWORLD)

	EventBus.battle_started.connect(_on_battle_started)
	EventBus.battle_ended.connect(_on_battle_ended)

	# Load enemy/dragon scenes
	_enemy_scene = load("res://entities/enemies/enemy_base.tscn")
	_wild_dragon_scene = load("res://entities/dragons/dragon_base.tscn")

	_spawn_overworld_entities()

func _spawn_overworld_entities() -> void:
	# Spawn some enemies around the overworld
	var enemy_data_paths := [
		"res://data/enemies/slime.tres",
		"res://data/enemies/goblin.tres",
	]

	var spawn_positions_enemies := [
		Vector3(8, 0, 5),
		Vector3(-6, 0, 10),
		Vector3(12, 0, -4),
		Vector3(-10, 0, -8),
		Vector3(5, 0, -12),
	]

	for i in spawn_positions_enemies.size():
		if not _enemy_scene:
			break
		var enemy := _enemy_scene.instantiate()
		enemy.position = spawn_positions_enemies[i]
		var data_path: String = enemy_data_paths[i % enemy_data_paths.size()]
		if ResourceLoader.exists(data_path):
			enemy.enemy_data = load(data_path)
		enemies_container.add_child(enemy)

	# Spawn wild dragons (rarer)
	var dragon_data_paths := [
		"res://data/dragons/fire_drake.tres",
		"res://data/dragons/storm_wyvern.tres",
		"res://data/dragons/stone_wyrm.tres",
	]

	var spawn_positions_dragons := [
		Vector3(18, 0, 15),
		Vector3(-16, 0, 18),
		Vector3(20, 0, -14),
	]

	for i in spawn_positions_dragons.size():
		if not _wild_dragon_scene:
			break
		var dragon := _wild_dragon_scene.instantiate()
		dragon.position = spawn_positions_dragons[i]
		var data_path: String = dragon_data_paths[i % dragon_data_paths.size()]
		if ResourceLoader.exists(data_path):
			dragon.dragon_data = load(data_path)
		dragons_container.add_child(dragon)

func _on_battle_started() -> void:
	if battle_arena:
		battle_arena.activate(camera, player)

func _on_battle_ended(result: StringName) -> void:
	if battle_arena:
		battle_arena.deactivate(camera, player)
	if result == "defeat":
		# On defeat: heal party and respawn at origin
		PartyManager.heal_all_dragons()
		player.global_position = Vector3(0, 1, 0)

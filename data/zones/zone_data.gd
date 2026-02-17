class_name ZoneData
extends Resource
## Defines a zone's ground, environment, spawns, portals, and decorations.

@export var zone_id: String = ""
@export var zone_name: String = ""

@export_group("Ground")
@export var ground_size: Vector3 = Vector3(60, 0.5, 60)
@export var ground_color: Color = Color(0.2, 0.35, 0.18, 1)

@export_group("Environment")
@export var sky_color: Color = Color(0.35, 0.5, 0.7, 1)
@export var ambient_color: Color = Color(0.4, 0.42, 0.5, 1)
@export var ambient_energy: float = 0.6
@export var light_color: Color = Color(1, 0.95, 0.85, 1)
@export var light_energy: float = 1.2
@export var fog_color: Color = Color(0.5, 0.55, 0.65, 1)
@export var fog_density: float = 0.002

@export_group("Spawns")
@export var enemy_spawns: Array[Dictionary] = []  # [{data_path, position}]
@export var dragon_spawns: Array[Dictionary] = []  # [{data_path, position}]
@export var npc_spawns: Array[Dictionary] = []  # [{data_path, position}]

@export_group("Portals")
@export var portals: Array[Dictionary] = []  # [{target_zone_path, position, label}]

@export_group("Decorations")
@export var decorations: Array[Dictionary] = []  # [{type, position, scale, color}]

@export_group("Player")
@export var default_spawn: Vector3 = Vector3(0, 1, 0)

class_name EnemyData
extends Resource
## Data for a non-dragon enemy.

@export var enemy_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var element: String = "neutral"

@export_group("Stats")
@export var max_hp: int = 60
@export var max_mp: int = 10
@export var attack: int = 8
@export var defense: int = 6
@export var agi: int = 8

@export_group("Combat")
@export var abilities: Array[Resource] = []  # AbilityData
@export var xp_reward: int = 30

@export_group("Visual")
@export var color_primary: Color = Color.WHITE
@export var color_secondary: Color = Color.GRAY
@export var model_scale: float = 1.0

func get_class_name() -> String:
	return "EnemyData"

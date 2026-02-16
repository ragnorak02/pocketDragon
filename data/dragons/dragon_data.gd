class_name DragonData
extends Resource
## Base data for a dragon species. Immutable template.

@export var dragon_id: String = ""
@export var dragon_name: String = ""
@export var element: String = "neutral"  # fire, ice, lightning, earth, neutral
@export var description: String = ""

# Base stats (level 1)
@export_group("Base Stats")
@export var base_hp: int = 80
@export var base_mp: int = 30
@export var base_atk: int = 12
@export var base_def: int = 10
@export var base_agi: int = 10

# Growth rates per level
@export_group("Growth")
@export var hp_growth: int = 8
@export var mp_growth: int = 3
@export var atk_growth: int = 2
@export var def_growth: int = 2
@export var agi_growth: int = 1

# Combat
@export_group("Combat")
@export var abilities: Array[Resource] = []  # AbilityData
@export var xp_reward: int = 50
@export var capture_difficulty: float = 1.0  # Higher = harder to catch
@export var base_level: int = 5

# Visual
@export_group("Visual")
@export var color_primary: Color = Color.WHITE
@export var color_secondary: Color = Color.GRAY
@export var model_scale: float = 1.0

func get_class_name() -> String:
	return "DragonData"

func get_stat_at_level(stat_name: String, level: int) -> int:
	match stat_name:
		"hp": return base_hp + hp_growth * (level - 1)
		"mp": return base_mp + mp_growth * (level - 1)
		"atk": return base_atk + atk_growth * (level - 1)
		"def": return base_def + def_growth * (level - 1)
		"agi": return base_agi + agi_growth * (level - 1)
	return 0
